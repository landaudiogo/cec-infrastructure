import {useEffect, useState } from 'react';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import TextField from '@mui/material/TextField';
import SendIcon from '@mui/icons-material/Send';
import CheckIcon from '@mui/icons-material/Check';

import './admin.css';

type User = {
    email: string, 
    role: string,
    client: number,
    group: number,
    account_uuid: string,
}

type UserListProps = {
    users: {
        [key: string]: User;
    };
    setUsers: React.Dispatch<React.SetStateAction<{[key: string]: User}>>
}

export default function UserList(props: UserListProps) {
    const { users, setUsers } = props;
    const [toEmail, setToEmail] = useState<undefined | string>(undefined);
    const [editing, setEditing] = useState<{[key: string]: string}>({});
    const [patchUser, setPatchUser] = useState<{email: string, group: number} | undefined>(undefined)

    useEffect(() => {
        if (!toEmail) 
            return;
        fetch(`/api/user/${toEmail}/send_email`, { method: "POST" })
            .then((res) => {
                if (!res.ok) {
                    throw new Error(`Request status not OK: ${res.status}`);
                }
                setToEmail(undefined);
                console.log(`emailed ${toEmail}`);
            })
            .catch((e) => {
                console.log(e)
            })
    }, [toEmail]);

    useEffect(() => {
        if (!patchUser) 
            return;
        fetch(`/api/user`, { method: "PATCH", body: JSON.stringify(patchUser), headers: {"Content-Type": "application/json"} })
            .then((res) => {
                if (!res.ok) {
                    throw new Error(`Request status not OK: ${res.status}`);
                }
                setPatchUser(undefined);
                setUsers((users) => {
                    let res = {...users};
                    res[patchUser.email] = {...users[patchUser.email], group: patchUser.group};
                    return res;
                });
                setEditing((editing) => {
                    let res = {...editing};
                    delete res[patchUser.email];
                    return res;
                });
                setPatchUser(undefined);
            })
            .catch((e) => {
                console.log(e)
            })
    }, [patchUser]);

    function sendEmail(email: string) {
        return () => {
            setToEmail(email);
        };
    }

    function editGroup(email: string) {
        return () => {
            setEditing((editing) => {
                let res = {...editing} 
                res[email] = "";
                return res;
            })
        };
    }

    function confirmEditing(email: string) {
        return () => {
            setPatchUser({email, group: Number(editing[email])});
        };
    }

    function handleGroupValue(email: string) {
        return (e: React.ChangeEvent<HTMLInputElement>) => {
            setEditing((editing) => {
                let res = {...editing};
                if (e.target.value.length <= 2) {
                    res[email] = e.target.value;
                }
                return res;
            });
        };
    }

    function validateNumber(e: React.KeyboardEvent<HTMLInputElement>) {
        if (!/[0-9]/.test(e.key) && (e.key !== "Backspace")) { 
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
                        key={user.email}
                        >
                            <TableCell align="left">{user.account_uuid}</TableCell>
                            <TableCell align="left">{user.email}</TableCell>
                            <TableCell align="left">{user.role}</TableCell>
                            <TableCell align="right">{user.client}</TableCell>
                            {user.email in editing ?
                                <TableCell align="right" onClick={editGroup(user.email)}>
                                    <input 
                                        autoFocus 
                                        onKeyDown={validateNumber} 
                                        onChange={handleGroupValue(user.email)} 
                                        value={editing[user.email]}
                                        className="group-input"
                                    />
                                </TableCell>:
                                <TableCell align="right" onClick={editGroup(user.email)}>{user.group != null ? user.group : "-"}</TableCell>
                            }
                            {user.email in editing ?
                                <TableCell align="center">
                                    <button className="confirm-button" onClick={confirmEditing(user.email)}><CheckIcon/></button>
                                </TableCell>:
                                <TableCell align="center">
                                    <button className="send-button" onClick={sendEmail(user.email)}><SendIcon/></button>
                                </TableCell>
                            }
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
    const [email, setEmail] = useState("");
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
                    res[body.email] = body;
                    return res;
                });
            })
            .catch((e) => {
                console.log(e)
            })

        setAdd(false);
        setEmail("");
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
                value={email}
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
                    res[user.email] = user;
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
