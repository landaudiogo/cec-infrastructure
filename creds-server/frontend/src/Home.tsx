import { useContext, useEffect } from "react";
import { useNavigate } from "react-router";
import { AuthContext } from "./AuthContext";
import { Admin } from "./Admin";
import { Files } from "./Files";
import { PatchEmail } from "./PatchEmail";

export function Home() {
    const navigate = useNavigate();
    const { user } = useContext(AuthContext);

    if (user === null) {
        navigate("/");
        return;
    }

    const { role, email } = user;

    useEffect(() => {
        navigate("/", { replace: true });
    }, [navigate]);


    return (<>
        {role === "admin" ?
            <Admin/>
            : (email !== null ? <Files/> : <PatchEmail/>)
        }
    </>)
}
