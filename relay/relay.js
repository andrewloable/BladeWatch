'use strict'
// BladeWatch's optional, owner-run Pear relay. See README.md in this folder.
//
// Hole punching cannot connect two peers that are BOTH behind randomizing NATs:
// hyperdht gives up with HOLEPUNCH_DOUBLE_RANDOMIZED_NATS without trying. A car on
// its built-in SIM and a phone on mobile data are exactly that. This relay sits on a
// host with a public IPv4 address and forwards such connections. It is a blind relay
// (holepunchto/blind-relay): it moves the Noise-encrypted stream and cannot read it.
//
// It serves only its owner. The owner types ONE relay key into this relay, the car
// and every companion. Each side derives two key pairs from it (deriveKeyPairs):
//   server -- the relay runs under it, so a member knows which relay to dial;
//   member -- the car and companions connect under it, and the relay's firewall
//             rejects every other key.
// flutter_pear's pear-end derives the same pairs; the test vector in
// test/relay.test.js pins the derivation so the two cannot drift apart.

const fs = require('fs')
const crypto = require('crypto')
const sodium = require('sodium-universal')
const DHT = require('hyperdht')
const { Server } = require('blind-relay')

const DEFAULT_KEY_FILE = '/etc/bladewatch-relay/key'
const DEFAULT_PORT = 49737
const KEY_DIGITS = 12
const LABEL = 'flutter_pear relay v1 '
// Argon2id, libsodium's "interactive" cost. Written as numbers, not the constant
// names, because they are part of the derivation and must never follow a library default.
const ARGON2_OPSLIMIT = 2
const ARGON2_MEMLIMIT = 64 * 1024 * 1024
const STATS_INTERVAL_MS = 10 * 60 * 1000

// A relay key is 12 random digits, written in groups of four: 4821-0937-5562.
// Spaces and dashes are ignored. Twelve, not six: anyone can scan the DHT for the
// relay each candidate key would derive, and a million candidates is a short scan.
function parseRelayKey (text) {
  const digits = String(text).replace(/[\s-]/g, '')
  if (!new RegExp('^[0-9]{' + KEY_DIGITS + '}$').test(digits)) {
    throw new Error('a relay key is ' + KEY_DIGITS + ' digits (spaces and dashes are ignored)')
  }
  return digits
}

function newRelayKey () {
  let digits = ''
  for (let i = 0; i < KEY_DIGITS; i++) digits += crypto.randomInt(10)
  return digits.match(/.{4}/g).join('-')
}

function blake2b (bytes, input) {
  const out = Buffer.alloc(bytes)
  sodium.crypto_generichash(out, input)
  return out
}

// root = Argon2id(the 12 digits, a fixed salt), so each guess costs ~64 MiB and real
// time even to someone who saw the relay's public key on the DHT. Then each role's
// Ed25519 seed is BLAKE2b-256(label + role, root).
function deriveKeyPairs (digits) {
  const salt = blake2b(sodium.crypto_pwhash_SALTBYTES, Buffer.from(LABEL + 'salt', 'utf8'))
  const root = Buffer.alloc(32)
  sodium.crypto_pwhash(root, Buffer.from(parseRelayKey(digits), 'utf8'), salt,
    ARGON2_OPSLIMIT, ARGON2_MEMLIMIT, sodium.crypto_pwhash_ALG_ARGON2ID13)
  const derive = (role) => DHT.keyPair(blake2b(32, Buffer.concat([Buffer.from(LABEL + role, 'utf8'), root])))
  return { server: derive('server'), member: derive('member') }
}

function ignore () {}

function createRelay ({ relayKey, port = DEFAULT_PORT, bootstrap } = {}) {
  const keyPairs = deriveKeyPairs(relayKey)
  // hyperdht binds the first free UDP port in [port, port + 5]: open that whole range.
  const dht = new DHT(bootstrap ? { port, bootstrap } : { port })
  const relay = new Server({ createStream: (opts) => dht.createRawStream({ ...opts, framed: true }) })
  const server = dht.createServer(
    // Returning true REJECTS. Only a peer that holds the relay key can derive the member key pair.
    { firewall: (remotePublicKey) => !remotePublicKey.equals(keyPairs.member.publicKey) },
    (socket) => {
      // A member that vanishes mid-relay -- a phone losing signal -- resets its
      // stream, and the session and socket emit that as an error. It is routine,
      // and without a listener it would crash the relay and every connection on
      // it. blind-relay already counts them in relay.stats.streams.errors.
      socket.on('error', ignore)
      relay.accept(socket, { id: socket.remotePublicKey }).on('error', ignore)
    }
  )
  return {
    dht,
    relay,
    server,
    publicKey: keyPairs.server.publicKey,
    listen: () => server.listen(keyPairs.server),
    // relay.close() alone waits for every session's pairings to end, which a
    // session carrying a live relayed connection never does on its own: a
    // shutdown would hang. Destroy the sessions first.
    close: async () => {
      for (const session of relay.sessions) session.destroy()
      await relay.close()
      await dht.destroy()
    }
  }
}

async function main () {
  if (process.argv[2] === '--new-key') {
    console.log(newRelayKey())
    return
  }
  const keyFile = process.env.RELAY_KEY_FILE || DEFAULT_KEY_FILE
  const r = createRelay({
    relayKey: fs.readFileSync(keyFile, 'utf8'),
    port: Number(process.env.RELAY_PORT || DEFAULT_PORT)
  })
  await r.listen()
  await r.dht.ready()
  // Never log the relay key itself. The public key and address are not secret.
  console.log('relay public key ' + r.publicKey.toString('hex'))
  // firewalled must be false on the relay host, or no member can reach it.
  console.log('public udp ' + r.dht.host + ':' + r.dht.port +
    ' firewalled=' + r.dht.firewalled + ' randomized=' + r.dht.randomized)

  setInterval(() => {
    const p = r.relay.stats.pairings
    console.log('sessions=' + r.relay.stats.sessions.active +
      ' pairings active=' + p.active + ' matched=' + p.matched +
      ' stream errors=' + r.relay.stats.streams.errors)
  }, STATS_INTERVAL_MS).unref()

  for (const signal of ['SIGINT', 'SIGTERM']) {
    process.once(signal, () => r.close().then(() => process.exit(0)))
  }
}

if (require.main === module) {
  main().catch((err) => {
    console.error('relay failed to start: ' + err.message)
    process.exit(1)
  })
}

module.exports = { parseRelayKey, newRelayKey, deriveKeyPairs, createRelay, DEFAULT_PORT }
