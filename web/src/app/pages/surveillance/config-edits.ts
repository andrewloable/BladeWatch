/**
 * The loaded config with this page's edits on top (BladeWatch-q0p4).
 *
 * SetConfig must carry EVERY field, not just the ones a page edits: proto3 JSON cannot send
 * `false`, so SurveillanceServiceImpl re-adds each omitted boolean as false -- and a Save that
 * left out cameraFront/Right/Rear/Left used to switch all four sentry cameras off.
 *
 * The loaded message's `$typeName` is dropped: an init shape may not carry it.
 */
export function withEdits<T extends object>(loaded: T | undefined, edits: Partial<T>): Omit<Partial<T>, '$typeName'> {
  const merged: Partial<T> & { $typeName?: unknown } = { ...(loaded ?? {}), ...edits };
  delete merged.$typeName;
  return merged;
}
