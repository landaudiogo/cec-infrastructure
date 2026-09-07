import { useContext, useEffect } from "react";
import { useNavigate } from "react-router";
import { AuthContext } from "./AuthContext";
import { Admin } from "./Admin";
import { Files } from "./Files";

export function Home() {
    const navigate = useNavigate();
    const { user: { role } } = useContext(AuthContext);

    useEffect(() => {
        navigate("/", { replace: true });
    }, [navigate]);

    return (<>
        {role === "admin" ? <Admin/> : <Files/>}
    </>)
}
