'use strict'
// RUNBOOK -- from relay/:  npm test
// Runs on a local hyperdht testnet; never touches the public DHT.

const test = require('node:test')
const assert = require('node:assert/strict')
const DHT = require('hyperdht')
const createTestnet = require('hyperdht/testnet')
const sodium = require('sodium-universal')
const { parseRelayKey, newRelayKey, deriveKeyPairs, createRelay } = require('../relay')

// The derivation test vector. flutter_pear's pear-end must produce these same two
// public keys from this relay key, or cars and companions dial the wrong relay.
const VECTOR = {
  key: '4821-0937-5562',
  server: '7d040c713b507b86738ce0968f56e879d1d40407976148ae1877fd2f16cfedd5',
  member: '9c84075c7e07e8ad1b227343c967ae2e49b9d30502d1ecdcfc5552baff394606'
}

test('a relay key is 12 digits; spaces and dashes are ignored', () => {
  assert.equal(parseRelayKey('482109375562'), '482109375562')
  assert.equal(parseRelayKey(VECTOR.key), '482109375562')
  assert.equal(parseRelayKey(' 4821 0937\n5562 '), '482109375562')
  for (const bad of ['', '482109', '4821093755621', '4821-0937-556x', '\u0664821-0937-5562']) {
    assert.throws(() => parseRelayKey(bad), /12 digits/, JSON.stringify(bad))
  }
})

test('a new relay key is 12 random digits in groups of four', () => {
  const keys = new Set()
  for (let i = 0; i < 20; i++) {
    const key = newRelayKey()
    assert.match(key, /^[0-9]{4}-[0-9]{4}-[0-9]{4}$/)
    keys.add(key)
  }
  assert.equal(keys.size, 20)
})

test('the derivation matches its test vector, whichever way the key is written', () => {
  for (const written of [VECTOR.key, '482109375562', '4821 0937 5562']) {
    const { server, member } = deriveKeyPairs(written)
    assert.equal(server.publicKey.toString('hex'), VECTOR.server, written)
    assert.equal(member.publicKey.toString('hex'), VECTOR.member, written)
  }
})

test('the derivation is Argon2id, then BLAKE2b-256 per role, then an Ed25519 seed key pair', () => {
  // Recomputed with libsodium directly, so a change in any helper shows up here.
  const salt = Buffer.alloc(16)
  sodium.crypto_generichash(salt, Buffer.from('flutter_pear relay v1 salt'))
  const root = Buffer.alloc(32)
  sodium.crypto_pwhash(root, Buffer.from('482109375562'), salt, 2, 64 * 1024 * 1024,
    sodium.crypto_pwhash_ALG_ARGON2ID13)
  for (const role of ['server', 'member']) {
    const seed = Buffer.alloc(32)
    sodium.crypto_generichash(seed, Buffer.concat([Buffer.from('flutter_pear relay v1 ' + role), root]))
    const publicKey = Buffer.alloc(32)
    const secretKey = Buffer.alloc(64)
    sodium.crypto_sign_seed_keypair(publicKey, secretKey, seed)
    assert.equal(publicKey.toString('hex'), VECTOR[role], role)
  }
})

let testnet
const cleanup = []
test.before(async () => {
  testnet = await createTestnet(3)
})
test.after(async () => {
  for (const fn of cleanup.reverse()) await fn().catch(() => {})
  await testnet.destroy()
})

async function startRelay (relayKey) {
  const relay = createRelay({ relayKey, port: 0, bootstrap: testnet.bootstrap })
  cleanup.push(() => relay.close())
  await relay.listen()
  return relay
}

function node (keyPair) {
  const dht = new DHT(keyPair ? { bootstrap: testnet.bootstrap, keyPair } : { bootstrap: testnet.bootstrap })
  cleanup.push(() => dht.destroy())
  return dht
}

function outcome (socket) {
  return new Promise((resolve) => {
    socket.once('open', () => resolve('open'))
    socket.once('error', (err) => resolve(err.code || err.message))
  })
}

test('the relay lets a member in and turns a stranger away', async () => {
  const relay = await startRelay(VECTOR.key)
  const { member } = deriveKeyPairs(VECTOR.key)

  const asMember = node().connect(relay.publicKey, { keyPair: member })
  assert.equal(await outcome(asMember), 'open')
  asMember.destroy()

  const asStranger = node().connect(relay.publicKey, { keyPair: DHT.keyPair() })
  assert.notEqual(await outcome(asStranger), 'open')
})

// A car-like server that can only be reached through the relay, and a phone-like
// client. Hole punching and local shortcuts are switched off, so the relay is the
// only path -- as for a car on its SIM and a phone on mobile data.
async function relayedEcho (relay, carKeyPair, phoneKeyPair) {
  const car = node(carKeyPair)
  const carServer = car.createServer(
    { holepunch: false, shareLocalAddress: false, relayThrough: relay.publicKey },
    (socket) => socket.on('error', () => {}).on('data', (data) => socket.write(data))
  )
  await carServer.listen(DHT.keyPair())

  const socket = node(phoneKeyPair).connect(carServer.publicKey, { localConnection: false, fastOpen: false })
  return new Promise((resolve) => {
    socket.once('open', () => socket.write(Buffer.from('ping')))
    socket.once('data', (data) => { socket.destroy(); resolve(data.toString()) })
    socket.once('error', (err) => resolve('error ' + (err.code || err.message)))
  })
}

test('two members connect through the relay', async () => {
  const relay = await startRelay(VECTOR.key)
  const { member } = deriveKeyPairs(VECTOR.key)

  assert.equal(await relayedEcho(relay, member, member), 'ping')
  assert.equal(relay.relay.stats.pairings.matched, 1)
})

test('a member vanishing mid-relay does not take the relay down', async () => {
  const relay = await startRelay(VECTOR.key)
  const { member } = deriveKeyPairs(VECTOR.key)

  // A relayed connection, then both ends drop without closing anything -- what a
  // phone losing signal does. The relay sees connection resets.
  const car = node(member)
  const phone = node(member)
  const carServer = car.createServer(
    { holepunch: false, shareLocalAddress: false, relayThrough: relay.publicKey },
    (socket) => socket.on('error', () => {}).on('data', (data) => socket.write(data))
  )
  await carServer.listen(DHT.keyPair())
  const socket = phone.connect(carServer.publicKey, { localConnection: false, fastOpen: false })
  await new Promise((resolve) => {
    socket.once('open', () => socket.write(Buffer.from('ping')))
    socket.once('data', resolve)
  })
  // An unhandled stream error inside the relay would surface here. In production
  // nothing catches it and the process dies; the test runner would swallow it.
  const uncaught = []
  const onUncaught = (err) => uncaught.push(err.code || err.message)
  process.on('uncaughtException', onUncaught)
  try {
    await phone.destroy()
    await car.destroy()
    await new Promise((resolve) => setTimeout(resolve, 500))
  } finally {
    process.off('uncaughtException', onUncaught)
  }
  assert.deepEqual(uncaught, [], 'the relay must not throw when a member vanishes')

  // Still alive: another pair of members is relayed.
  assert.equal(await relayedEcho(relay, member, member), 'ping')
  assert.equal(relay.relay.stats.pairings.matched, 2)
})

test('a phone without the relay key is not relayed', async () => {
  const relay = await startRelay(VECTOR.key)
  const { member } = deriveKeyPairs(VECTOR.key)

  assert.match(await relayedEcho(relay, member, DHT.keyPair()), /^error /)
  assert.equal(relay.relay.stats.pairings.matched, 0)
})
