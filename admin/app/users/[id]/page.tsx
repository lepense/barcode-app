export default async function UserDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  // TODO: Fetch user data from Firebase when configured

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">User Detail</h1>
      <p className="text-zinc-500 mb-4">User ID: {id}</p>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Profile Card */}
        <div className="bg-white dark:bg-zinc-900 rounded-lg border border-zinc-200 dark:border-zinc-800 p-6">
          <h2 className="text-lg font-semibold mb-4">Profile</h2>
          <p className="text-zinc-500 text-sm">
            Connect Firebase to load user profile.
          </p>
        </div>

        {/* Entitlements Card */}
        <div className="bg-white dark:bg-zinc-900 rounded-lg border border-zinc-200 dark:border-zinc-800 p-6">
          <h2 className="text-lg font-semibold mb-4">Entitlements</h2>
          <p className="text-zinc-500 text-sm">
            Connect Firebase to load entitlements.
          </p>
        </div>
      </div>

      {/* Purchase History */}
      <div className="mt-6 bg-white dark:bg-zinc-900 rounded-lg border border-zinc-200 dark:border-zinc-800 p-6">
        <h2 className="text-lg font-semibold mb-4">Purchase History</h2>
        <p className="text-zinc-500 text-sm">
          Connect Firebase to load purchase history.
        </p>
      </div>

      {/* Design Usage */}
      <div className="mt-6 bg-white dark:bg-zinc-900 rounded-lg border border-zinc-200 dark:border-zinc-800 p-6">
        <h2 className="text-lg font-semibold mb-4">Design Usage</h2>
        <p className="text-zinc-500 text-sm">
          Connect Firebase to load design usage per card.
        </p>
      </div>

      {/* Admin Actions */}
      <div className="mt-6 bg-white dark:bg-zinc-900 rounded-lg border border-zinc-200 dark:border-zinc-800 p-6">
        <h2 className="text-lg font-semibold mb-4">Admin Actions</h2>
        <div className="flex gap-3">
          <button className="px-4 py-2 bg-yellow-500 text-white rounded-lg text-sm font-medium hover:bg-yellow-600 transition-colors">
            Disable User
          </button>
          <button className="px-4 py-2 bg-blue-500 text-white rounded-lg text-sm font-medium hover:bg-blue-600 transition-colors">
            Export Data (JSON)
          </button>
          <button className="px-4 py-2 bg-red-500 text-white rounded-lg text-sm font-medium hover:bg-red-600 transition-colors">
            Delete User
          </button>
        </div>
      </div>
    </div>
  );
}
