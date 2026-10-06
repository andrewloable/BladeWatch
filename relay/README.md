# BladeWatch relay

An optional server you run yourself, so the companion app can reach your car when a direct
connection is impossible.

**When you need it.** When the car is online through its built-in SIM and your phone is on mobile
data, both sit behind carrier NATs that peer-to-peer connections cannot cross. Without a relay the
companion cannot reach the car in that situation, and you have to put the phone on Wi-Fi. With a
relay, that connection goes through your server instead. Every connection that works directly today
stays direct: the relay is only used when hole punching cannot work.

**How it stays yours.** You create one **relay key**: 12 digits, like `4821-0937-5562`. You enter the
same key in three places: this server, the car, and each companion. The relay refuses every
connection that does not prove it has the key, so other people cannot use it, even other BladeWatch
owners. The relay only forwards encrypted data. It cannot see your video, your car's data or your
login.

Requires BladeWatch 1.4.1.3 or later on the car and on every companion.

## What you need

- A Linux server that is always on, with systemd. These steps use Ubuntu 22.04 or later.
- A **public IPv4 address** that reaches the server: either on the server itself, or mapped one to
  one to it, as AWS, Oracle Cloud and most VPS providers do. A server behind a home router or
  carrier NAT will not work.
- Inbound **UDP ports 49737 to 49742** open. The relay uses 49737, or the next free port up to 49742.
- Node.js 20 or later.
- Very little power: 1 vCPU and 512 MB of RAM are plenty. Outbound traffic is only what goes
  through the relay, so check your provider's traffic allowance.

## 1. Install Node.js

```sh
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version
```

## 2. Install the relay

Create a service account and a folder for it:

```sh
sudo useradd --system --home /opt/bladewatch-relay --shell /usr/sbin/nologin bladewatch-relay
sudo mkdir -p /opt/bladewatch-relay
```

Download the relay from the [BladeWatch release](https://github.com/andrewloable/BladeWatch/releases)
that matches your car. Each release carries it as `bladewatch-relay-<tag>.tar.gz`; for v1.4.1.3 that is
[bladewatch-relay-v1.4.1.3.tar.gz](https://github.com/andrewloable/BladeWatch/releases/download/v1.4.1.3/bladewatch-relay-v1.4.1.3.tar.gz).
On the server:

```sh
TAG=v1.4.1.3   # the release you installed on the car
cd /tmp
curl -fLO "https://github.com/andrewloable/BladeWatch/releases/download/$TAG/bladewatch-relay-$TAG.tar.gz"
tar -xzf "bladewatch-relay-$TAG.tar.gz"
sudo cp -f bladewatch-relay/* /opt/bladewatch-relay/
rm -rf bladewatch-relay "bladewatch-relay-$TAG.tar.gz"
cd /opt/bladewatch-relay
sudo npm ci --omit=dev
```

With the GitHub CLI, `gh release download "$TAG" -R andrewloable/BladeWatch -p 'bladewatch-relay-*.tar.gz'`
fetches the same file (leave out `"$TAG"` for the latest release).

From a source checkout instead, copy the same six files to the server, then into place on it:

```sh
cd BladeWatch/relay
scp relay.js check.js package.json package-lock.json bladewatch-relay.service README.md <you>@<server>:/tmp/
# then on the server:
cd /tmp
sudo mv -f relay.js check.js package.json package-lock.json bladewatch-relay.service README.md /opt/bladewatch-relay/
cd /opt/bladewatch-relay
sudo npm ci --omit=dev
```

`npm ci` installs the exact library versions in `package-lock.json`, which match what the car runs.

## 3. Create the relay key

```sh
sudo mkdir -p /etc/bladewatch-relay
cd /opt/bladewatch-relay
sudo sh -c 'umask 077; node relay.js --new-key > /etc/bladewatch-relay/key'
sudo chown -R bladewatch-relay: /etc/bladewatch-relay
sudo chmod 700 /etc/bladewatch-relay
sudo cat /etc/bladewatch-relay/key
```

The last command shows the key. You will type it into the car and each companion. Keep it like a
Wi-Fi password: anyone who has it can use your relay. They still cannot reach your car, which needs
pairing.

You may write any 12 digits into the key file instead, but a random key is what keeps strangers out.
Never use a short or guessable number.

## 4. Run it as a service

```sh
sudo cp -f /opt/bladewatch-relay/bladewatch-relay.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now bladewatch-relay
```

It now starts at boot and restarts if it stops.

## 5. Open the UDP ports

Allow inbound **UDP 49737-49742 from anywhere** in your provider's firewall, and on the server itself
if it runs one.

| Where | What to do |
|---|---|
| AWS EC2 | Instance > Security > security group > Edit inbound rules > Custom UDP, 49737-49742, source 0.0.0.0/0 |
| AWS Lightsail | Instance > Networking > IPv4 firewall > Add rule > Custom, UDP, 49737-49742 |
| Oracle Cloud | Subnet security list or network security group: ingress, UDP, destination ports 49737-49742, source 0.0.0.0/0 |
| Other providers | Their firewall panel: allow inbound UDP 49737-49742 |
| ufw on the server | `sudo ufw allow 49737:49742/udp` (check first with `sudo ufw status`) |

Oracle's Ubuntu images also block inbound traffic in iptables, even after the cloud rule. On those:

```sh
sudo iptables -I INPUT -p udp --dport 49737:49742 -j ACCEPT
sudo netfilter-persistent save
```

## 6. Check it

```sh
journalctl -u bladewatch-relay -n 20 --no-pager
```

Look for these two lines:

```
relay public key <64 hex characters>
public udp <your server's public IP>:49737 firewalled=false randomized=false
```

- `firewalled=true` means the UDP ports are not open yet. Recheck step 5, then
  `sudo systemctl restart bladewatch-relay`.
- `randomized=true` means the server sits behind a NAT that changes ports. It cannot be a relay;
  use a server with a public IP as described above.

Then test it from your own computer, which needs Node.js 20 or later and this folder:

```sh
cd BladeWatch/relay
npm ci --omit=dev
(umask 077; printf '%s\n' '<your relay key>' > relay-key)
node check.js relay-key
rm -f relay-key
```

It passes when it prints `member: let in` and `stranger: turned away`.

## 7. Turn it on in BladeWatch

1. **In the car:** Settings > **Relay access** > turn on **Use my relay**, type the key in
   **Relay key**, and save.
2. **In each companion:** Settings > **Relay access** > turn on **Use my relay**, type the same key,
   and save.

Both sides need it. If only the car has the key, the relay turns the phone away. The apps show only
the last four digits of a saved key, so you can compare them.

## Change the key

Do this if the key may have leaked:

```sh
cd /opt/bladewatch-relay
sudo sh -c 'umask 077; node relay.js --new-key > /etc/bladewatch-relay/key'
sudo systemctl restart bladewatch-relay
sudo cat /etc/bladewatch-relay/key
```

The old key stops working at once. Enter the new one in the car and in every companion.

## Update the relay

Download and unpack the new release's archive as in step 2 (it replaces the files in
`/opt/bladewatch-relay`, never your key in `/etc/bladewatch-relay`), then:

```sh
cd /opt/bladewatch-relay
sudo npm ci --omit=dev
sudo cp -f bladewatch-relay.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart bladewatch-relay
```

The relay's library versions follow the car's. Update it when a BladeWatch release says so.

## Remove the relay

Turn off **Use my relay** in the car and every companion first, then:

```sh
sudo systemctl disable --now bladewatch-relay
sudo rm -f /etc/systemd/system/bladewatch-relay.service
sudo rm -rf /opt/bladewatch-relay /etc/bladewatch-relay
sudo userdel bladewatch-relay
```

## Troubleshooting

| What you see | What it means |
|---|---|
| `check.js` prints `member: NOT let in` | The relay is not running, or its UDP ports are closed. See step 6. |
| `check.js` prints `stranger: LET IN` | This is not the relay from this folder, or it was modified. Reinstall it. |
| The companion still cannot reach the car on mobile data | Check that **Use my relay** is on in both apps and the last four digits match. |
| Nothing changes on Wi-Fi | Expected. Direct connections never use the relay. |

The log prints a line every 10 minutes with how many connections the relay has paired. If that
number grows when you are not using BladeWatch, change the key.

## What the relay can see

- **Cannot see:** your video, recordings, car data, commands or login. Everything it forwards is
  encrypted end to end between the car and the companion.
- **Can see:** the IP addresses of your car and phones, when they connect, and how much data passes.

The relay never writes the key to its log.

## For developers

`relay.js` is also the reference for how the key becomes key pairs. flutter_pear's pear-end does the
same on the car and in the companion, and the test vector below must hold in both.

1. Strip spaces and dashes. Exactly 12 ASCII digits remain.
2. salt = BLAKE2b, 16-byte output, of the UTF-8 string `flutter_pear relay v1 salt`.
3. root = Argon2id13 (libsodium `crypto_pwhash`), 32 bytes, password = the 12 digits as UTF-8,
   that salt, opslimit 2, memlimit 67108864.
4. seed(role) = BLAKE2b-256 of the UTF-8 string `flutter_pear relay v1 <role>` followed by root.
5. key pair(role) = Ed25519 from that seed (hyperdht `DHT.keyPair`), for roles `server` and `member`.

The relay listens under the server key pair and accepts only the member public key. Members open
their relay connections under the member key pair.

Test vector: key `4821-0937-5562` gives

- server public key `7d040c713b507b86738ce0968f56e879d1d40407976148ae1877fd2f16cfedd5`
- member public key `9c84075c7e07e8ad1b227343c967ae2e49b9d30502d1ecdcfc5552baff394606`

Run the tests, which use a local test network and never the public DHT:

```sh
cd relay && npm ci && npm test
```

The library versions in `package.json` are pinned to the ones in the car's pear-end bundle. Move them
only together with that bundle.
