// Definiciones de tipos para Deno en Edge Functions de Supabase

// Namespace global de Deno
declare namespace Deno {
  export namespace env {
    export function get(key: string): string | undefined;
  }
}

// Variable global Deno
declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
};

// Tipos para módulos externos
declare module "https://deno.land/std@0.168.0/http/server.ts" {
  export interface ServeOptions {
    port?: number;
    hostname?: string;
    signal?: AbortSignal;
  }
  
  export function serve(
    handler: (request: Request) => Response | Promise<Response>,
    options?: ServeOptions
  ): Promise<void>;
}

declare module "https://esm.sh/@supabase/supabase-js@2" {
  export interface SupabaseClientOptions {
    auth?: {
      autoRefreshToken?: boolean;
      persistSession?: boolean;
      detectSessionInUrl?: boolean;
    };
    global?: {
      headers?: Record<string, string>;
    };
  }

  export interface User {
    id: string;
    email?: string;
    [key: string]: any;
  }

  export interface AuthResponse {
    data: {
      user: User | null;
    };
    error: Error | null;
  }

  export interface SupabaseQueryBuilder {
    select(columns?: string): SupabaseQueryBuilder;
    insert(values: any): SupabaseQueryBuilder;
    update(values: any): SupabaseQueryBuilder;
    delete(): SupabaseQueryBuilder;
    eq(column: string, value: any): SupabaseQueryBuilder;
    neq(column: string, value: any): SupabaseQueryBuilder;
    gt(column: string, value: any): SupabaseQueryBuilder;
    gte(column: string, value: any): SupabaseQueryBuilder;
    lt(column: string, value: any): SupabaseQueryBuilder;
    lte(column: string, value: any): SupabaseQueryBuilder;
    like(column: string, pattern: string): SupabaseQueryBuilder;
    ilike(column: string, pattern: string): SupabaseQueryBuilder;
    is(column: string, value: any): SupabaseQueryBuilder;
    in(column: string, values: any[]): SupabaseQueryBuilder;
    contains(column: string, value: any): SupabaseQueryBuilder;
    containedBy(column: string, value: any): SupabaseQueryBuilder;
    rangeGt(column: string, range: string): SupabaseQueryBuilder;
    rangeGte(column: string, range: string): SupabaseQueryBuilder;
    rangeLt(column: string, range: string): SupabaseQueryBuilder;
    rangeLte(column: string, range: string): SupabaseQueryBuilder;
    rangeAdjacent(column: string, range: string): SupabaseQueryBuilder;
    overlaps(column: string, value: any): SupabaseQueryBuilder;
    textSearch(column: string, query: string, options?: any): SupabaseQueryBuilder;
    match(query: Record<string, any>): SupabaseQueryBuilder;
    not(column: string, operator: string, value: any): SupabaseQueryBuilder;
    or(filters: string): SupabaseQueryBuilder;
    filter(column: string, operator: string, value: any): SupabaseQueryBuilder;
    order(column: string, options?: { ascending?: boolean; nullsFirst?: boolean }): SupabaseQueryBuilder;
    limit(count: number): SupabaseQueryBuilder;
    range(from: number, to: number): SupabaseQueryBuilder;
    single(): SupabaseQueryBuilder;
    maybeSingle(): SupabaseQueryBuilder;
    csv(): SupabaseQueryBuilder;
    geojson(): SupabaseQueryBuilder;
    explain(options?: any): SupabaseQueryBuilder;
    rollback(): SupabaseQueryBuilder;
    returns(): SupabaseQueryBuilder;
    then<TResult1 = any, TResult2 = never>(
      onfulfilled?: ((value: any) => TResult1 | PromiseLike<TResult1>) | undefined | null,
      onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null
    ): Promise<TResult1 | TResult2>;
  }

  export interface SupabaseClient {
    auth: {
      getUser(): Promise<AuthResponse>;
      signIn(credentials: any): Promise<AuthResponse>;
      signUp(credentials: any): Promise<AuthResponse>;
      signOut(): Promise<{ error: Error | null }>;
    };
    from(table: string): SupabaseQueryBuilder;
    rpc(fn: string, args?: any): SupabaseQueryBuilder;
    storage: {
      from(bucketId: string): any;
    };
    functions: {
      invoke(functionName: string, options?: any): Promise<any>;
    };
  }

  export function createClient(
    url: string, 
    key: string, 
    options?: SupabaseClientOptions
  ): SupabaseClient;
}

// Tipos globales adicionales para Edge Functions
declare global {
  interface Request {
    json(): Promise<any>;
  }
  
  interface Response {
    new(body?: BodyInit | null, init?: ResponseInit): Response;
  }
  
  interface Console {
    log(...args: any[]): void;
    error(...args: any[]): void;
    warn(...args: any[]): void;
    info(...args: any[]): void;
  }
  
  const console: Console;
  const fetch: (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;
  const crypto: Crypto;
  const btoa: (data: string) => string;
  const TextEncoder: {
    new(): {
      encode(input: string): Uint8Array;
    };
  };
} 