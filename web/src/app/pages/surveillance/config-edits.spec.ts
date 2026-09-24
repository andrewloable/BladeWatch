import { describe, expect, it } from 'vitest';
import { withEdits } from './config-edits';

describe('withEdits (BladeWatch-q0p4)', () => {
  it('keeps every loaded field the page does not edit', () => {
    const loaded = { cameraFront: true, cameraRight: true, cameraRear: true, cameraLeft: true, deterrentAction: 'FLASH', sensitivity: 3 };
    const sent = withEdits(loaded, { sensitivity: 5 });
    expect(sent).toEqual({ ...loaded, sensitivity: 5 });
  });

  it('lets an edit turn a flag off, and survives a config that never loaded', () => {
    expect(withEdits({ nightMode: true }, { nightMode: false })).toEqual({ nightMode: false });
    expect(withEdits(undefined, { sensitivity: 2 })).toEqual({ sensitivity: 2 });
  });
});

describe('withEdits and protobuf-es messages', () => {
  it('drops $typeName, which an init shape may not carry', () => {
    expect(withEdits({ $typeName: 'bladewatch.v1.SurveillanceConfig', cameraFront: true }, {})).toEqual({ cameraFront: true });
  });
});
