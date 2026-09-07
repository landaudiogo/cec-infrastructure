use anyhow::Result;
use r2d2::Pool;
use r2d2_sqlite::{rusqlite::params, SqliteConnectionManager};

pub fn init_sql(pool: Pool<SqliteConnectionManager>, admin_uuid: &str) -> Result<()> {
    let res = pool.get()?
        .execute_batch(&format!("
            CREATE TABLE IF NOT EXISTS user (
                client_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                email TEXT UNIQUE,
                group_id INTEGER,
                account_uuid TEXT UNIQUE NOT NULL,
                role TEXT NOT NULL
            );
            INSERT INTO user(account_uuid, email, role) VALUES ('{admin_uuid}', 'd.landau@uu.nl', 'admin') ON CONFLICT DO NOTHING;
        "))?;
    Ok(())
}
