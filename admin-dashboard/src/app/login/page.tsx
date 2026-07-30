import { LoginForm } from './login-form';

export default function LoginPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-neutral-950 px-4">
      <div className="w-full max-w-sm rounded-xl border border-neutral-700 bg-neutral-900 p-8 shadow-sm">
        <h1 className="text-xl font-semibold text-neutral-300">Play Smart Admin</h1>
        <p className="mt-1 text-sm text-neutral-400">Sign in with your admin account.</p>
        <div className="mt-6">
          <LoginForm />
        </div>
      </div>
    </div>
  );
}
