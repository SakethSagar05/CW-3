// Tiny in-memory stand-in for the Admin Firestore API used by the functions.
// It records every write so tests can assert "nothing was written".
export function createFakeFirestore(initial = {}) {
  const docs = new Map(Object.entries(initial));
  const writes = [];
  const reads = [];

  const snapshot = (path) => ({
    exists: docs.has(path),
    data: () => (docs.has(path) ? { ...docs.get(path) } : undefined),
  });
  const ref = (path) => ({
    path,
    get: async () => {
      reads.push(path);
      return snapshot(path);
    },
    set: async (value) => {
      writes.push(path);
      docs.set(path, { ...value });
    },
  });

  // Serialise transactions so two concurrent calls behave like Firestore's
  // retry-on-conflict: the second one sees the first one's write.
  let queue = Promise.resolve();
  return {
    docs,
    writes,
    reads,
    doc: ref,
    runTransaction(fn) {
      const run = queue.then(() =>
        fn({
          get: (r) => r.get(),
          set: (r, value) => {
            writes.push(r.path);
            docs.set(r.path, { ...value });
          },
        }),
      );
      queue = run.catch(() => {});
      return run;
    },
  };
}
