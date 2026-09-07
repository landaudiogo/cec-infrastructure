import { useEffect, useState } from "react";
import { useNavigate } from "react-router";

import TextField from "@mui/material/TextField";
import IconButton from "@mui/material/IconButton";
import InputAdornment from "@mui/material/InputAdornment";

import Visibility from "@mui/icons-material/Visibility";
import VisibilityOff from "@mui/icons-material/VisibilityOff";

import "./login.css";

export function Login() {
    const [accountUuid, setAccountUuid] = useState("");
    const [login, setLogin] = useState(false);
    const [showPassword, setShowPassword] = useState(false);

    const navigate = useNavigate();

    useEffect(() => {
        if (login) {
            fetch(`/api/authenticate?account_uuid=${accountUuid}`)
                .then(res => {
                    if (res.status === 200) {
                        navigate("/");
                    } else {
                        setAccountUuid("");
                    }
                });

            setLogin(false);
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
                        id="account-uuid"
                        label="uuid"
                        type={showPassword ? "text" : "password"}
                        variant="outlined"
                        value={accountUuid}
                        onChange={handleInputChange}
                        onKeyDown={handleKeyDown}
                        slotProps={{
                            input: {
                                endAdornment: (
                                    <InputAdornment position="end">
                                        <IconButton
                                            onClick={() => setShowPassword(!showPassword)}
                                            edge="end"
                                        >
                                            {showPassword
                                                ? <VisibilityOff />
                                                : <Visibility />
                                            }
                                        </IconButton>
                                    </InputAdornment>
                                ),
                            },
                        }}
                    />

                    <button className='login-button' onClick={(_) => setLogin(true)}>login</button>
                </div>
            </div>
        </div>
    );
}
