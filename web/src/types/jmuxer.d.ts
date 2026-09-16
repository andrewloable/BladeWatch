/**
 * jmuxer ships no type declarations, so importing it is an implicit `any` under `strict`
 * (TS7016) and fails the typecheck gate.
 *
 * Declared as an untyped module rather than hand-writing its API: the only consumer is
 * `src/app/pages/live/mse-player.ts`, which uses a handful of methods, and a hand-written
 * shape would be a second source of truth that silently rots when the package updates.
 */
declare module 'jmuxer';
