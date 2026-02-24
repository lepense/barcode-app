export default function AnalyticsPage() {
  // TODO: Fetch design usage analytics from Firebase when configured

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Design Analytics</h1>

      <div className="bg-white dark:bg-zinc-900 rounded-lg border border-zinc-200 dark:border-zinc-800 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-800/50">
              <th className="text-left px-4 py-3 font-medium">Design ID</th>
              <th className="text-left px-4 py-3 font-medium">Total Applies</th>
              <th className="text-left px-4 py-3 font-medium">Last Used</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td colSpan={3} className="px-4 py-8 text-center text-zinc-500">
                Connect Firebase to load design analytics.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
