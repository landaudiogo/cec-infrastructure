import { useContext, useEffect, useState } from "react";
import { jwtDecode } from 'jwt-decode';
import { AuthContext } from './AuthContext';
import { useNavigate } from "react-router";

import TextField from '@mui/material/TextField';

import './login.css';

type JWTPayload = {
    role: string,
    user: string,
};

export function Login() {
    const [accountUuid, setAccountUuid] = useState("");
    const [login, setLogin] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        if (login) {
            fetch(`/api/authenticate?account_uuid=${accountUuid}`)
                .then(res => {
                    if (res.status == 200) {
                        navigate("/")
                    } else {
                        setAccountUuid("");
                    }
                });
            setLogin(false)
        }
    }, [login]);

    function handleInputChange(e: React.ChangeEvent<HTMLInputElement>) {
        setAccountUuid(e.target.value);
    }

    function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
        if (e.key === "Enter") {
            setLogin(true);
        }
    }

    return (
        <div className="login-page">
            <div className="login-container">
                <h1>INFOMCEC</h1>
                <div className="login-control">
                <TextField 
                    id="outlined-basic" 
                    label="account uuid"
                    type="password"
                    variant="outlined" 
                    onChange={handleInputChange}
                    onKeyDown={handleKeyDown}
                />
                <button className='login-button' onClick={(_) => setLogin(true)}>login</button>
                </div>
            </div>
        </div>
    );
}
