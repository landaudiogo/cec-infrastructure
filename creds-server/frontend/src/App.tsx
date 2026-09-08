import { Routes, Route } from "react-router";
import { Login } from './Login.tsx';
import { Home } from './Home.tsx';
import { AuthContext } from './AuthContext.tsx';
import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { Files } from "./Files";
import type { User } from "./types"

function App() {
    const [user, setUser] = useState<null | User>(null);
    const [attemptAuth, setAttemptAuth] = useState(false);
    const value = {user, setUser};
    const navigate = useNavigate();
    
    useEffect(() => {
        fetch("/api/user")  
            .then((res) => {
                if (!res.ok) {
                    throw new Error(`Request status not OK: ${res.status}`);
                }
                return res.json();
            })
            .then((body) => {
                setAttemptAuth(true);
                setUser({ ...body })
            })
            .catch((_) => {
                setAttemptAuth(true);
                navigate("/login");
            })

    }, [attemptAuth])

    return (
        <AuthContext.Provider value={value}>
        {attemptAuth && 
            <Routes>
                <Route path='/' element={<Home/>}/> 
                <Route path='/files' element={<Files/>}/> 
                <Route path='/login' element={<Login/>}/> 
                <Route path='*' element={<Home/>}/> 
            </Routes>
        }
        </AuthContext.Provider>
    )
}

export default App
