import { createContext } from "react"
import type { User } from "./types.tsx"

export type AuthContextType = {
  user: User | null;
  setUser: React.Dispatch<React.SetStateAction<User | null>>;
};

export const AuthContext = createContext<AuthContextType>({
    user: null,
    setUser: () => {},
});
