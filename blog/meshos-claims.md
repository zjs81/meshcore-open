# I checked the MeshOS "exposed" post. It doesn't hold up.

*November 7, 2026*

A post on meshoskey.com claims the MeshOS Companion Android app has a hidden pipeline that scores your photos, reads your contacts and texts, and quietly uploads it all to the developer. That's a serious accusation, so I spent the day checking it. I'm the developer of meshcore-open (a different, open source MeshCore client) and have no connection to MeshOS. I just wanted to know if it was true.

Short version: it isn't. The post says it analysed v1.0.31. I pulled that exact build apart and none of the things it describes are in there. The strings it quotes don't exist, the addresses it gives point at unrelated code, and the app doesn't even have the Android permissions needed to read contacts or SMS. I also ran it with fake contacts, texts and photos planted on the phone and decrypted all of its traffic. None of the planted data ever left the device.

Details below so anyone can check my work.

## The APKs

All from the official releases page, [github.com/andymux/meshos-releases](https://github.com/andymux/meshos-releases/releases). The SHA-256s match the digests GitHub publishes for each release:

| Version | SHA-256 |
|---|---|
| 1.0.31 | `fd4970e1b1446ddb0d2985c3b54837857a970da663b212fdb3d3c1f07ac47103` |
| 1.0.32 | `a6a3b04dcc741a6a59525f7dc2ab883f57927665edf9c30826db0a1af679a18b` |
| 1.0.33 | `f42f8834a010499e72dad5f5138b054e7c1a2e6a3155c15edf37ebfd76543183` |
| 1.0.34 | `426d43cabfaba76a0119715e4160c6369449ee50aa7858b0fb023a3533dcf6ec` |
| 1.0.35 | `50264287e2ccd4e02cc6615879f4b54eb2392d9b1eb56329f001a65360f8422e` |

I did the deep analysis on 1.0.31 (the one the post is about) and 1.0.35 (latest). For the others I checked permissions and strings. The Dart code lives in `lib/arm64-v8a/libapp.so`; for 1.0.31 that file hashes to `cdc8abe1…ec83402`, so you can make sure you're looking at the same bytes I was.

## Contacts and SMS: not possible

This one is simple. To read contacts or texts on Android an app has to declare `READ_CONTACTS` / `READ_SMS` and the user has to grant them. None of the five versions declare either one, or any permission to browse the photo library. The permission list is identical across all five. Without those permissions Android just refuses, no matter what the code tries to do.

I looked anyway. There's no contacts or SMS code in the Java side, in the Dart side, or in any of the bundled native libraries. When the app says "contacts" it means radio/mesh contacts.

## The strings the post quotes

The post names a lot of specific identifiers. If the pipeline existed, these would have to be in the binary. I searched 1.0.31 for every one of them (raw file, the Dart constant pool, and the Java bytecode):

```
harvest_v1   harvest_seq   harvest_blob
mqtt.meshcore.co.uk   meshcore/companion/.../harvest/kill   img/kill
com.meshcore.companion/harvest   /contacts   /sms   /upload   /mqtt
content://com.android.providers.contacts   raw_contacts
Pictures/Insta   Snapchat/Sent   Snapchat/Received   Telegram/Image
Selfie   ootd   lingerie   battery_level   screen_on_duration
ImageUpload: harvest_seq=   USER_PRESENT
```

Zero hits for all of them. The post says the strings are XOR'd with 0xB3, so I XOR'd the whole file with 0xB3 and searched again. Still nothing. I also tried every other single-byte key. Nothing.

The only identifier from the post that does exist is `com.meshcore.companion/signing`, which the post itself says is normal.

## The addresses

The post gives exact locations (offsets) in the app's code file for each piece of the supposed pipeline, and even for a few text strings and a licence key. Those are easy to check: you jump to that spot in the file and see what's there. In this file the offsets map directly onto the code, so there's no room for an "it's a different kind of address" mix-up.

Two things to know when reading the table. First, a function, a piece of text and a key are different kinds of things and live in different parts of the file. Text and keys sit in a data area. The code area only holds instructions. Second, a real function has a clear starting point, and pointing into the middle of one makes no sense.

| Offset | The post says it's | What's actually there |
|---|---|---|
| 0x8A1C40 | the photo tag scanner | The middle of Dart's own built-in networking code, which ships with every Flutter app. Nothing to do with photos. |
| 0x8A2080 | a lookup table for photo tags | A single instruction in that same networking function. Not a table. |
| 0x8A20A0 | a table of folder names | Another instruction in the same function, one that jumps to other code. No folder names anywhere. |
| 0x8B4100 | the text of the contacts database address | An instruction that compares two numbers. Not text. |
| 0x8B4210 | the code that reads contacts and SMS | The middle of Flutter's screen-layout code (the part that works out where things go on screen). |
| 0x8C1A00 | the code that packs up the stolen data | The middle of Flutter's image-effects code (blur and colour filters). |
| 0x8C1A58 | the word "nonce" | An instruction that unpacks a number. Not text. |
| 0x8C1A60 | the word "harvest_v1" | An instruction that reads a value from memory. Not text. |
| 0x8C1A80 | the app's licence key | Instructions that compare numbers. The real licence key is somewhere else entirely, stored with the app's data where it belongs. |
| 0x8D0400 | where the hidden upload starts | The middle of a big number math routine used by the encryption library. It's an instruction that jumps backwards within that routine. |
| 0x8E2000 | the remote "kill switch" handler | A function that only compares decimal numbers and has no text in it at all, so it can't be handling server messages or topic names. |

So none of the "functions" are where functions start, and the "text" and "key" are actually program instructions. The special number the post says marks a "harvest" upload (0x1DD3) isn't used anywhere in the app either. I can't explain where these locations came from, but they don't describe this app.

If you want to check the raw details: at 0x8A2080 the instruction is `ldr x16, [x26,#0x48]`, at 0x8C1A58 it's `sbfx x6, x0, #1, #0x1f`, at 0x8C1A60 it's `ldur w7, [x3, #0xb]`, the "licence key" bytes at 0x8C1A80 start `22 7c 41 93 df 00 02 eb`, and at 0x8D0400 it's `b #0x8d01e0`.

## What the app really does with photos

Some of what the post describes is real. It just isn't hidden. There is an upload to `https://tiles.meshcore.co.uk/img`, it is `application/octet-stream`, it does send `X-MeshOS-Enc: gcm`, and it is AES-GCM. That's the "Send a photo" button.

When you send a photo the app picks it through the normal Android picker, generates a random key, encrypts the image, uploads the ciphertext and puts a link in the chat like `…/i/abc.jpg#k=KEY`. Everything after the `#` never goes to the server. So the server only stores data it can't open, and only people who can read the chat message can view the photo. The upload code is only reached from three places: sending a photo or voice note in a DM, sending one in a channel, and broadcasting your own profile picture. All three are things you do on purpose. The upload format is a 12-byte nonce, the ciphertext, then a 16-byte tag. I suspect that 12 is where the post's "12-field blob" came from. The image code also has an 8-step loop that lowers JPEG quality until the file is small enough, which might be where "eight thumbnails" came from.

The key isn't derived from the licence or a device ID. It's random every time. You'll see why I'm sure about that in the next part.

## Running it with bait

I set up an Android 15 emulator, forced every connection through mitmproxy with its certificate installed as a system cert (the app doesn't pin certs, so all HTTPS decrypted fine), and kept a packet capture running. Then I planted things the post says the app goes after:

- three contacts: Alice Baitwell, Bob Decoy, Carol Canary, with example.com emails
- four texts, including a fake bank code, a gate code, and one tagged BAITSMS-ALPHA
- solid colour images in DCIM/Camera, Pictures/Screenshots and Pictures/Snapchat

I used 1.0.35 and 1.0.31 normally. I sent a photo, set a profile picture, chatted, rebooted, locked and unlocked, and left them idle. Every upload I saw lined up with something I did:

- **1.0.35:** one `POST /img` (2,909 bytes), when I sent a photo.
- **1.0.31:** a signed `POST /avatar` with `"delete":true` on first start (clears any old profile pic for the new identity), and another `POST /avatar` when I set my profile picture.
- **Both:** MQTT login, subscriptions, the node advert, a tiny diagnostics message, and my chat messages.

Everything else was downloads: map tiles, avatars, a version check. None of the bait names, numbers, codes or filenames showed up anywhere in the traffic.

For the one photo upload, I took the key out of the app's own message store (`#k=0uiiv2YsDTlgwpR1KRRpSQ`) and decrypted the 2,909 bytes I'd captured. Out came a 2,881-byte JPEG: the blue square from the Snapchat folder that I had picked, and nothing else. No extra data, no metadata, no bait text. Here it is:

<img src="meshos-claims-decrypted-upload.jpg" alt="The decrypted upload: a solid blue square" width="96" height="96">

Unlock triggers don't exist either. Nothing in the app listens for unlock or screen-on events. The only startup hook is a boot receiver that opens the app if you've turned on "start on boot", which is off by default.

## Second opinions

I didn't want to rely only on my own reading, so I also gave the decompiled code and the post's claims to three AI models: OpenAI's Codex, Z.ai's GLM 5.3 and Claude Mythos 5.1. I didn't tell any of them what I'd found. All three came back with the same answer on the main question: none of the claimed harvesting exists. Codex and Mythos each re-checked every offset against the raw 1.0.31 binary and got the same instructions I did.

I didn't just take their word on the details either. Everything new they raised, I checked myself before it went in here, and anything that didn't hold up was left out.

## Things I'd actually flag to the developer

The app isn't spyware, but there are real issues worth fixing:

- MQTT goes to `167.99.90.25:1883` with no TLS, using one username and password baked into every copy of the app. Adverts and presence are readable on the wire. (Credentials left out here on purpose.) On a fresh install it connected within seconds of first launch, before I'd touched anything.
- The `X-MeshOS-Key` header on uploads is a shared key that anyone can pull out of the APK.
- If a user turns on location in adverts, the lat/lon goes out over that unencrypted MQTT connection.
- Photos are re-encoded as JPEG (quality 85, then 78, 68, 58 until under about 450 KB), but if decoding fails the original file is uploaded as-is. I couldn't confirm whether location data gets stripped in the normal case, because my test images didn't have any to begin with. Someone should test this with a real phone photo that has GPS data in it.
- The `meshos/chat/control` up/down message isn't signed.
- A small diagnostics message (app version, uptime, Android build) is sent as soon as MQTT connects and doesn't seem to be disclosed.
- The manifest allows unencrypted HTTP everywhere (`usesCleartextTraffic="true"`). It's needed for updating repeaters over local Wi-Fi, but it isn't limited to that.
- Profile pictures are stored publicly, which is expected but worth knowing.

## What I didn't check

I can't see the server. I only tested the Android app, versions 1.0.31 to 1.0.35, not the T-Deck build or anything older. My disassembly covered about 95% of the Dart code; the rest can't get around Android permissions anyway. Each live session ran for around half an hour, not days.

## Check it yourself

1. Grab the APKs from the releases page and compare the hashes above.
2. `aapt dump permissions MeshOS-v1.0.31.apk`. No contacts, SMS or media permissions.
3. `unzip MeshOS-v1.0.31.apk lib/arm64-v8a/libapp.so`, then `grep -c harvest libapp.so`. You'll get 0.
4. `xxd -s 0x8C1A60 -l 16 libapp.so` and the other offsets. Run the bytes through any ARM64 disassembler.
5. For the code: [blutter](https://github.com/worawit/blutter) for the Dart side, [jadx](https://github.com/skylot/jadx) for Java.
6. For traffic: emulator with `-http-proxy` pointed at mitmproxy and the mitmproxy CA added as a system cert.

---

I did this because I think it's the right thing to do. Accusing a developer of secretly building spyware is serious, and people deserve to know whether it's true. I'd want the same if it were my app. Everything above can be checked by anyone, and if I've got something wrong I'd like to hear about it.

\- Zach
