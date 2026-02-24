export default function DashboardPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <DashboardCard title="Total Users" value="—" subtitle="Registered users" />
        <DashboardCard title="Pro Users" value="—" subtitle="Lifetime purchases" />
        <DashboardCard title="Designs Used" value="—" subtitle="Total applies" />
      </div>
      <div className="mt-8">
        <h2 className="text-lg font-semibold mb-4">Recent Activity</h2>
        <div className="bg-white dark:bg-zinc-900 rounded-lg border border-zinc-200 dark:border-zinc-800 p-6">
          <p className="text-zinc-500">
            Connect Firebase to see live data. Set FIREBASE_SERVICE_ACCOUNT_KEY
            environment variable with your service account JSON.
          </p>
        </div>
      </div>
    </div>
  );
}

function DashboardCard({
  title,
  value,
  subtitle,
}: {
  title: string;
  value: string;
  subtitle: string;
}) {
  return (
    <div className="bg-white dark:bg-zinc-900 rounded-lg border border-zinc-200 dark:border-zinc-800 p-6">
      <p className="text-sm text-zinc-500 mb-1">{title}</p>
      <p className="text-3xl font-bold">{value}</p>
      <p className="text-xs text-zinc-400 mt-1">{subtitle}</p>
    </div>
  );
}
