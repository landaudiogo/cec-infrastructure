use indoc::{formatdoc, indoc};
use anyhow::Result;
use uuid::Uuid;
use jwt::Claims;
use r2d2::Pool;
use r2d2_sqlite::{rusqlite::params, SqliteConnectionManager};
use serde_json::{json, Value};
use tokio;
use tracing::{info, warn, Level};
use axum_extra::extract::cookie::{CookieJar, Cookie};
use axum::{
    body::Body, extract::{Query, RawPathParams, State}, http::{header, StatusCode}, response::{IntoResponse, Response}, routing::{get, post, patch}, Json, Router
};
use axum_macros::debug_handler;
use std::{collections::HashMap, env, fs::{self, File}, path::Path, sync::Arc};
use serde::{Deserialize, Serialize};
use tokio_util::io::ReaderStream;

use sendgrid::error::SendgridError;
use sendgrid::v3::*;

mod jwt;
mod sql;

#[derive(Deserialize)]
struct CreateUser {
    email: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
struct User {
    account_uuid: String,
    email: Option<String>,
    client: u64,
    group: Option<u64>,
    role: String,
}

#[derive(Deserialize, Debug)]
struct AccountUuid {
    account_uuid: String,
}


async fn authenticate(
    State(pool): State<Pool<SqliteConnectionManager>>,
    jar: CookieJar,
    query: Query<AccountUuid>,
) -> Result<(CookieJar, StatusCode), StatusCode> {
    let conn = pool.get().unwrap();

    let res = conn
        .prepare(
            "
            SELECT account_uuid, role
            FROM user
            WHERE account_uuid = ?;
            ",
        )
        .unwrap()
        .query_row(params![query.account_uuid], |row| {
            Ok((
                row.get(0).unwrap(),
                row.get(1).unwrap(),
            ))
        });

    match res {
        Ok((account_uuid, role)) => {
            let claims = Claims::new(account_uuid, role);
            let token = jwt::encode(&claims)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            Ok((
                jar.add(
                    Cookie::build(("token", token))
                        .http_only(true),
                ),
                StatusCode::OK,
            ))
        }
        Err(_) => {
            info!("invalid uuid `{}`", query.account_uuid);
            Err(StatusCode::UNAUTHORIZED)
        }
    }
}

type Users = Vec<User>;

async fn get_users(
    State(pool): State<Pool<SqliteConnectionManager>>,
    jar: CookieJar,
) -> Result<(StatusCode, Json<Users>), StatusCode> {
    let token = jar.get("token").ok_or(StatusCode::NOT_FOUND)?;
    match jwt::decode(token.value()) {
        Ok(token_data) => {
            let role = token_data.claims.role;
            if role != "admin" {
                info!("Attempting to get users with role {role}");
                return Err(StatusCode::UNAUTHORIZED);
            }
        }, 
        Err(_) => {
            return Err(StatusCode::FORBIDDEN);
        }
    }

    let conn = pool.get().unwrap(); 
    let mut query = conn
        .prepare("
            SELECT email, client_id, group_id, role, account_uuid FROM user;
        ")
        .unwrap();
    let users: Vec<User> = query.query_map([], |row| {
            Ok(User {
                email: row.get(0).unwrap(),
                client: row.get::<usize, u64>(1).unwrap(),
                group: row.get::<usize, Option<u64>>(2).unwrap(),
                role: row.get::<usize, String>(3).unwrap(),
                account_uuid: row.get::<usize, String>(4).unwrap(),
            })
        })
        .unwrap()
        .map(|user| user.unwrap())
        .collect();

    return Ok((StatusCode::OK, Json(users)))
}

async fn get_user(
    State(pool): State<Pool<SqliteConnectionManager>>,
    jar: CookieJar,
) -> Result<(StatusCode, Json<User>), StatusCode> {
    let token = jar.get("token").ok_or(StatusCode::NOT_FOUND)?;
    let account_uuid = match jwt::decode(token.value()) {
        Ok(token_data) => {
            token_data.claims.account_uuid
        }, 
        Err(_) => {
            return Err(StatusCode::NOT_FOUND);
        }
    };

    let conn = pool.get().unwrap(); 
    let user = conn
        .prepare("
            SELECT email, client_id, group_id, role, account_uuid FROM user WHERE account_uuid = ?;
        ").unwrap()
        .query_row(params![account_uuid], |row| {
            Ok(User {
                email: row.get(0).unwrap(),
                client: row.get::<usize, u64>(1).unwrap(),
                group: row.get::<usize, Option<u64>>(2).unwrap(),
                role: row.get::<usize, String>(3).unwrap(),
                account_uuid: row.get::<usize, String>(4).unwrap(),
            })
        }).expect(&format!("User `{}` missing from db", account_uuid));

    return Ok((StatusCode::OK, Json(user)))
}

type Files = Vec<String>;

async fn get_files(
    State(pool): State<Pool<SqliteConnectionManager>>,
    jar: CookieJar,
) -> Result<(StatusCode, Json<Value>), StatusCode> {
    let token = jar.get("token").ok_or(StatusCode::NOT_FOUND)?;
    let account_uuid = match jwt::decode(token.value()) {
        Ok(token_data) => {
            token_data.claims.account_uuid
        }, 
        Err(_) => {
            return Err(StatusCode::NOT_FOUND);
        }
    };

    let conn = pool.get().unwrap(); 
    let user = conn
        .prepare("
            SELECT email, client_id, group_id, role, account_uuid FROM user WHERE account_uuid = ?;
        ").unwrap()
        .query_row(params![account_uuid], |row| {
            Ok(User {
                email: row.get(0).unwrap(),
                client: row.get::<usize, u64>(1).unwrap(),
                group: row.get::<usize, Option<u64>>(2).unwrap(),
                role: row.get::<usize, String>(3).unwrap(),
                account_uuid: row.get::<usize, String>(4).unwrap(),
            })
        }).expect(&format!("User `{}` missing from db", account_uuid));

    let credentials_dir = env::var("CREDENTIALS_DIR").expect("CREDENTIALS_DIR unset");

    let mut body = serde_json::Map::new();
    let client = format!("client{}", user.client);
    let client_dir = Path::new(&credentials_dir).join("clients").join(&client);
    let mut client_files = Vec::new();
    for entry in fs::read_dir(client_dir).unwrap().into_iter().map(|entry| entry.unwrap()) {
        let path = entry.path();
        let file_name = path.file_name().unwrap().to_str().unwrap();
        client_files.push(file_name.into());
    }
    body.insert(client, Value::Array(client_files));

    let Some(group) = user.group else {
        return Ok((StatusCode::OK, Json(Value::Object(body))));
    };
    let group = format!("group{}", group);
    let group_dir = Path::new(&credentials_dir).join("groups").join(&group);
    let Ok(dir_entries) = fs::read_dir(group_dir) else { 
        return Ok((StatusCode::OK, Json(Value::Object(body)))); 
    };
    let mut group_files = Vec::new();
    for entry in dir_entries {
        let Ok(entry) = entry else { continue; };
        let path = entry.path();
        let file_name = path.file_name().unwrap().to_str().unwrap();
        group_files.push(file_name.into());
    }
    body.insert(group, Value::Array(group_files));
    Ok((StatusCode::OK, Json(Value::Object(body))))
}

async fn patch_user(
    State(pool): State<Pool<SqliteConnectionManager>>,
    jar: CookieJar,
    Json(payload): Json<User>,
) -> Result<StatusCode, StatusCode> {
    let token = jar.get("token").ok_or(StatusCode::UNAUTHORIZED)?;
    let Ok(token_data) = jwt::decode(token.value()) else {
        return Err(StatusCode::FORBIDDEN);
    };

    if (token_data.claims.role != "admin") {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let conn = pool.get().unwrap();
    let rows_updated = conn
        .prepare("
            UPDATE user
            SET
                email = ?,
                role = ?,
                group_id = ?,
                client_id = ?
            WHERE
                account_uuid = ?
        ").unwrap()
        .execute(params![payload.email, payload.role, payload.group, payload.client, payload.account_uuid])
        .map_err(|e| {
            warn!("sql error: {payload:?} {e:?}");
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    if rows_updated > 0 { Ok(StatusCode::OK) } else { Err(StatusCode::NOT_FOUND) }
}

#[derive(Deserialize)]
struct PatchUserEmail {
    account_uuid: String,
    email: String,
}

async fn patch_user_email(
    State(pool): State<Pool<SqliteConnectionManager>>,
    jar: CookieJar,
    Json(payload): Json<PatchUserEmail>,
) -> Result<StatusCode, StatusCode> {
    let token = jar.get("token").ok_or(StatusCode::UNAUTHORIZED)?;
    let Ok(token_data) = jwt::decode(token.value()) else {
        return Err(StatusCode::FORBIDDEN);
    };

    if ((token_data.claims.role != "admin") && (token_data.claims.account_uuid != payload.account_uuid)) {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let conn = pool.get().unwrap();
    let rows_updated = conn
        .prepare("
            UPDATE user
            SET
                email = ?
            WHERE
                account_uuid = ?
        ").unwrap()
        .execute(params![payload.email, payload.account_uuid])
        .map_err(|e| StatusCode::FORBIDDEN)?;

    if rows_updated > 0 { Ok(StatusCode::OK) } else { Err(StatusCode::NOT_FOUND) }
}

async fn create_user(
    State(pool): State<Pool<SqliteConnectionManager>>,
    jar: CookieJar,
    Json(payload): Json<CreateUser>,
) -> Result<(StatusCode, Json<User>), StatusCode> {
    let token = jar.get("token").ok_or(StatusCode::UNAUTHORIZED)?;
    let email = match jwt::decode(token.value()) {
        Ok(token_data) => {
            let role = token_data.claims.role;
            if role != "admin" {
                info!("Attempting to create user with role {role}");
                return Err(StatusCode::UNAUTHORIZED);
            }
            payload.email
        }, 
        Err(_) => {
            return Err(StatusCode::FORBIDDEN);
        }
    };

    let conn = pool.get().unwrap(); 
    let user = conn
        .prepare("
            INSERT INTO user(client_id, email, role, account_uuid) 
            SELECT MAX(client_id) + 1, ?, ?, ?
            FROM user
            RETURNING email, client_id, group_id, role, account_uuid
        ").unwrap()
        .query_row(params![email, "student", Uuid::new_v4().to_string()], |row| {
            Ok(User {
                email: row.get::<usize, Option<String>>(0).unwrap(),
                client: row.get::<usize, u64>(1).unwrap(),
                group: row.get::<usize, Option<u64>>(2).unwrap(),
                role: row.get::<usize, String>(3).unwrap(),
                account_uuid: row.get::<usize, String>(4).unwrap(),
            })
        })
        .map_err(|e| StatusCode::FORBIDDEN)?;
    
    Ok((StatusCode::CREATED, Json(user)))
}

async fn download_file(
    State(pool): State<Pool<SqliteConnectionManager>>,
    jar: CookieJar, 
    params: RawPathParams
) -> impl IntoResponse {
    let requested_file = match params.iter().filter(|(key, _)| *key == "file").map(|(_, v)| v).next() {
        Some(file) => file,
        None => return Err(StatusCode::NOT_FOUND)
    };

    let token = jar.get("token").ok_or(StatusCode::NOT_FOUND)?;
    let account_uuid = match jwt::decode(token.value()) {
        Ok(token_data) => {
            token_data.claims.account_uuid
        }, 
        Err(_) => {
            return Err(StatusCode::NOT_FOUND);
        }
    };

    let conn = pool.get().unwrap(); 
    let user = conn
        .prepare("
            SELECT email, client_id, group_id, role, account_uuid FROM user WHERE account_uuid = ?;
        ").unwrap()
        .query_row(params![account_uuid], |row| {
            Ok(User {
                email: row.get(0).unwrap(),
                client: row.get::<usize, u64>(1).unwrap(),
                group: row.get::<usize, Option<u64>>(2).unwrap(),
                role: row.get::<usize, String>(3).unwrap(),
                account_uuid: row.get::<usize, String>(4).unwrap(),
            })
        }).expect(&format!("User `{}` missing from db", account_uuid));

    let conn = pool.get().unwrap(); 

    let mut valid_files = vec![format!("client{}.zip", user.client)];
    if let Some(group) = user.group {
        valid_files.push(format!("group{}.zip", group))
    }

    if !valid_files.iter().any(|v| v==requested_file) {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let credentials_dir = env::var("CREDENTIALS_DIR").expect("CREDENTIALS_DIR unset");
    let mut file_path = Path::new(&credentials_dir).to_path_buf();
    if requested_file.starts_with("client") {
        file_path.push("clients")
    } else {
        file_path.push("groups")
    };
    file_path.push(requested_file);

    let file = match tokio::fs::File::open(file_path).await {
        Ok(file) => file,
        Err(err) => return Err(StatusCode::NOT_FOUND),
    };

    let stream = ReaderStream::new(file);
    let body = Body::from_stream(stream);

    let headers = [
        (header::CONTENT_TYPE, String::from("application/zip")),
        (
            header::CONTENT_DISPOSITION,
            format!("attachment; filename=\"{}\"", requested_file),
        ),
    ];

    Ok((headers, body))
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt().with_max_level(Level::INFO).init();

    let db = format!("{}/db.sqlite", env::var("DB_DIR").expect("DB_DIR unset"));
    let db = Path::new(&db);
    fs::create_dir_all(db.parent().unwrap());
    let manager = SqliteConnectionManager::file(db);
    let pool = r2d2::Pool::new(manager).unwrap();
    sql::init_sql(pool.clone(), &env::var("ADMIN_UUID").expect("ADMIN_UUID unset"))?;
    // send_admin_token().await?;

    let app = Router::new()
        .route("/api/users", post(create_user))
        .route("/api/users", get(get_users))
        .route("/api/user", get(get_user))
        .route("/api/user", patch(patch_user))
        .route("/api/user/email", patch(patch_user_email))
        .route("/api/authenticate", get(authenticate))
        .route("/api/files", get(get_files))
        .route("/api/download/{file}", get(download_file))
        .with_state(pool);

    let bind_address = "0.0.0.0:3000";
    info!("Server listening on {bind_address}");

    let listener = tokio::net::TcpListener::bind(bind_address).await.unwrap();
    axum::serve(listener, app).await.unwrap(); 

    Ok(())
}
