import {useEffect, useState } from 'react';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import TextField from '@mui/material/TextField';
import CheckIcon from '@mui/icons-material/Check';
import EditOutlinedIcon from '@mui/icons-material/EditOutlined';

import type { User } from './types';

import './admin.css';


type UserListProps = {
    users: {
        [key: string]: User;
    };
    setUsers: React.Dispatch<React.SetStateAction<{[key: string]: User}>>
}

export default function UserList(props: UserListProps) {
    const { users, setUsers } = props;
    const [editing, setEditing] = useState<{[key: string]: User}>({});
    const [viewUUID, setViewUUID] = useState<null | string>(null);
    const [patchUser, setPatchUser] = useState<User | null>(null)

    useEffect(() => {
        if (!patchUser) 
            return;
        fetch(`/api/user`, { method: "PATCH", body: JSON.stringify(patchUser), headers: {"Content-Type": "application/json"} })
            .then((res) => {
                if (!res.ok) {
                    throw new Error(`Request status not OK: ${res.status}`);
                }
                setPatchUser(null);
                setUsers((users) => {
                    let res = {...users};
                    res[patchUser.account_uuid] = { ...patchUser };
                    return res;
                });
                setEditing((editing) => {
                    let res = {...editing};
                    delete res[patchUser.account_uuid];
                    return res;
                });
                setPatchUser(null);
            })
            .catch((e) => {
                console.log(e)
            })
    }, [patchUser]);

    function editGroup(account_uuid: string) {
        return () => {
            setEditing((editing) => {
                let res = {...editing} 
                res[account_uuid] = {...users[account_uuid]};
                return res;
            })
        };
    }

    function confirmEditing(account_uuid: string) {

        return () => {
            setPatchUser((_) => {
                return {...editing[account_uuid]}
            })
        };
    }

    function handleClientValue(account_uuid: string) {
        return (e: React.ChangeEvent<HTMLInputElement>) => {
            setEditing((editing) => {
                let res = {...editing};
                if (e.target.value.length <= 2) {
                    res[account_uuid].client = parseInt(e.target.value) || 0;
                }
                return res;
            });
        };
    }

    function handleGroupValue(account_uuid: string) {
        return (e: React.ChangeEvent<HTMLInputElement>) => {
            setEditing((editing) => {
                let res = {...editing};
                if (e.target.value.length <= 2) {
                    res[account_uuid].group = parseInt(e.target.value) || null;
                }
                return res;
            });
        };
    }

    function handleEmailValue(account_uuid: string) {
        return (e: React.ChangeEvent<HTMLInputElement>) => {
            setEditing((editing) => {
                let res = {...editing};
                let value: string | null = e.target.value;
                value.trim();
                value = value.length === 0 ? null : value;
                res[account_uuid].email = value;
                return res;
            });
        };
    }

    function handleRoleValue(account_uuid: string) {
        return (e: React.ChangeEvent<HTMLInputElement>) => {
            setEditing((editing) => {
                let res = {...editing};
                res[account_uuid].role = e.target.value;
                return res;
            });
        };
    }

    function validateNumber(e: React.KeyboardEvent<HTMLInputElement>) {
      const allowedKeys = [
        "Backspace",
        "Delete",
        "ArrowLeft",
        "ArrowRight",
        "ArrowUp",
        "ArrowDown",
        "Tab",
        "Shift",
      ];

      if (!/[0-9]/.test(e.key) && !allowedKeys.includes(e.key)) {
        e.preventDefault();
      }
    }

    return (
        <TableContainer className="creds-table-container">
            <Table sx={{ minWidth: "500px" }} aria-label="simple table">
                <TableHead>
                    <TableRow>
                        <TableCell align="center">UUID</TableCell>
                        <TableCell align="center">Email</TableCell>
                        <TableCell align="center">Role</TableCell>
                        <TableCell align="center">Client</TableCell>
                        <TableCell align="center">Group</TableCell>
                        <TableCell/>
                    </TableRow>
                </TableHead>
                <TableBody>
                    {Object.values(users).sort((a,b) => a.client > b.client ? 1 : -1).map((user) => (
                        <TableRow
                            key={user.account_uuid}
                        >
                            <TableCell
                                align="center"
                                sx={{
                                    width: "400px",
                                    minWidth: "400px",
                                }}
                                onMouseDown={(_) => setViewUUID(user.account_uuid)}
                                onMouseUp={(_) => setViewUUID(null)}
                            >
                                { user.account_uuid === viewUUID ? user.account_uuid : "*".repeat(36)}
                            </TableCell>
                            <TableCell align="left">
                                {user.account_uuid in editing ?
                                    <input 
                                        onChange={handleEmailValue(user.account_uuid)} 
                                        value={editing[user.account_uuid].email || ""}
                                        className="email-input"
                                    />
                                    :<>{user.email}</>
                                }
                            </TableCell>
                            <TableCell align="left">
                                {user.account_uuid in editing ?
                                    <input 
                                        onChange={handleRoleValue(user.account_uuid)} 
                                        value={editing[user.account_uuid].role || ""}
                                        className="role-input"
                                    />
                                    :<>{user.role}</>
                                }
                            </TableCell>
                            <TableCell align="right">
                                {user.account_uuid in editing ?
                                    <input 
                                        onKeyDown={validateNumber} 
                                        onChange={handleClientValue(user.account_uuid)} 
                                        value={editing[user.account_uuid].client}
                                        className="numeric-input"
                                    />
                                    :<>{user.client}</>
                                }
                            </TableCell>
                            <TableCell align="right">
                                {user.account_uuid in editing ?
                                    <input 
                                        autoFocus 
                                        onKeyDown={validateNumber} 
                                        onChange={handleGroupValue(user.account_uuid)} 
                                        value={editing[user.account_uuid].group || ""}
                                        className="numeric-input"
                                    />
                                    :<>{user.group != null ? user.group : "-"}</>
                                }
                            </TableCell>
                            <TableCell align="center">
                                {user.account_uuid in editing ?
                                        <button className="confirm-button" onClick={confirmEditing(user.account_uuid)}><CheckIcon/></button>
                                        :<button className="edit-button" onClick={editGroup(user.account_uuid)}><EditOutlinedIcon/></button>
                                }
                            </TableCell>
                        </TableRow>
                    ))}
                </TableBody>
            </Table>
        </TableContainer>
    );
}

type AddUserProps = {
    setUsers: React.Dispatch<React.SetStateAction<{[key: string]: User}>>
};

function AddUser(props: AddUserProps) {
    const [email, setEmail] = useState<null | string>(null);
    const [add, setAdd] = useState(false)
    const { setUsers } = props;

    useEffect(() => {
        if (!add) return;
        fetch("/api/users", {
            method: "POST", 
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({ email })
        })
            .then((res) => {
                if (!res.ok) {
                    throw new Error(`Request status not OK: ${res.status}`);
                }
                return res.json();
            })
            .then((body) => {
                setUsers((_users) => {
                    let res: {[key: string]: User} = {..._users};
                    res[body.account_uuid] = body;
                    return res;
                });
            })
            .catch((e) => {
                console.log(e)
            })

        setAdd(false);
        setEmail(null);
    }, [add])

    function handleInputChange(e: React.ChangeEvent<HTMLInputElement>) {
        setEmail(e.target.value);
    }

    function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
        if (e.key === "Enter") {
            setAdd(true);
        }
    }

    return (
        <div className="add-user-container"> 
            <TextField 
                id="outlined-basic" 
                label="email" 
                variant="outlined" 
                value={email ? email : ""}
                onChange={handleInputChange}
                onKeyDown={handleKeyDown}
            />
            <button className='add-button' onClick={() => setAdd(true)}>Add</button>
        </div> 
    );

}

export function Admin() {
    const [users, setUsers] = useState<{[key: string]: User}>({});

    useEffect(() => {
        fetch("/api/users")
            .then((res) => {
                if (!res.ok) {
                    throw new Error(`Request status not OK: ${res.status}`);
                }
                return res.json();
            })
            .then((body) => {
                let res: {[key: string]: User} = {}
                for (const elem of body) {
                    let user = elem as User;
                    res[user.account_uuid] = user;
                }
                setUsers(res);
            })
            .catch((e) => {
                console.log(e)
            })
    }, [])

    return (
        <div className="admin-page">
            <AddUser setUsers={setUsers}/>    
            <UserList users={users} setUsers={setUsers}/>
        </div>
    );
}
