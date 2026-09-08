import { useContext, useEffect, useState } from "react";
import { AuthContext } from "./AuthContext";
import { useNavigate } from "react-router";

import TextField from "@mui/material/TextField";
import Alert from '@mui/material/Alert';

import "./patchEmail.css";

function isEmailValid(email: string): boolean {
    return /^[.a-z0-9]+@uu\.nl$/.test(email)
}

export function PatchEmail() {
    const [email, setEmail] = useState("");
    const [update, setUpdate] = useState(false);
    const [invalid, setInvalid] = useState(false);
    const { user, setUser } = useContext(AuthContext);
    const navigate = useNavigate();

    if (user === null) {
        navigate("/");
        return;
    }
    
    useEffect(() => {
        if (!update) 
            return;

        if (!isEmailValid(email)) {
            setUpdate(false);
            setInvalid(true);
            return;
        }

        fetch(
            "/api/user/email", 
            { 
                method: "PATCH", 
                body: JSON.stringify({ account_uuid: user.account_uuid, email }),
                headers: {"Content-Type": "application/json"} 
            }
        )
            .then(res => {
                if (res.status === 200) {
                    navigate("/");
                    setUser((curr) => {
                        if (curr === null) {
                            return user;
                        }

                        let res = {...curr};
                        res["email"] = email;
                        return res;
                    })
                } else {
                    setInvalid(true);
                    setUpdate(false);
                }
            });

        setUpdate(false);
    }, [update]);

    function handleInputChange(e: React.ChangeEvent<HTMLInputElement>) {
        if (invalid) setInvalid(false);
        setEmail(e.target.value);
    }

    function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
        if (e.key === "Enter") {
            setUpdate(true);
        }
    }

    return (
        <div className="patch-page">
            {invalid &&
                <Alert  severity="error">
                    <h4>Could not update email</h4>
                    <div className="patch-alert">
                        Make sure you use a valid UU email address (e.g. d.landau@uu.nl), and that your email isn't already registered.
                    </div>
                </Alert>
            }
            <div className="patch-container">
                <h2>Welcome to CEC!</h2>
                <span>Please update your email:</span>

                <div className="patch-control">
                    <TextField
                        id="email"
                        label="email"
                        type="text"
                        error={invalid}
                        variant="outlined"
                        value={email}
                        onChange={handleInputChange}
                        onKeyDown={handleKeyDown}
                    />

                    <button className='patch-button' onClick={(_) => setUpdate(true)}>update</button>
                </div>
            </div>
        </div>
    );
}
