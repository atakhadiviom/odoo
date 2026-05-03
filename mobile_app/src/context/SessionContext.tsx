import React, { createContext, useContext, useEffect, useState } from 'react';

import { odooApi } from '../lib/odoo';
import { AccountPayload } from '../types';

interface SessionContextValue {
  account: AccountPayload | null;
  loading: boolean;
  login: (login: string, password: string) => Promise<void>;
  loginWithGoogle: (idToken: string) => Promise<void>;
  logout: () => Promise<void>;
  refresh: () => Promise<void>;
}

const SessionContext = createContext<SessionContextValue | undefined>(undefined);

export function SessionProvider({ children }: React.PropsWithChildren) {
  const [account, setAccount] = useState<AccountPayload | null>(null);
  const [loading, setLoading] = useState(false);

  const refresh = async () => {
    setLoading(true);
    try {
      setAccount(await odooApi.getAccount());
    } catch {
      setAccount(null);
    } finally {
      setLoading(false);
    }
  };

  const login = async (loginValue: string, password: string) => {
    setLoading(true);
    try {
      await odooApi.authenticate(loginValue, password);
      setAccount(await odooApi.getAccount());
    } finally {
      setLoading(false);
    }
  };

  const loginWithGoogle = async (idToken: string) => {
    setLoading(true);
    try {
      setAccount(await odooApi.loginWithGoogle(idToken));
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    setLoading(true);
    try {
      await odooApi.logout();
      setAccount(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    refresh().catch(() => {
      setAccount(null);
    });
  }, []);

  return (
    <SessionContext.Provider
      value={{ account, loading, login, loginWithGoogle, logout, refresh }}
    >
      {children}
    </SessionContext.Provider>
  );
}

export function useSession() {
  const context = useContext(SessionContext);
  if (!context) {
    throw new Error('useSession must be used within SessionProvider');
  }
  return context;
}
