# Chess

Play chess with someone on a channel, or watch other people's games. Moves go over the mesh as small channel data packets, so games suit a slow network: each move can take its time, and anyone on the channel can follow along.

## Requirements

- Companion firmware v1.15 or newer, on every radio that plays or watches. Older firmware can't send or receive channel data, and the games sheet says so.
- Everyone involved must be on the same channel (same key). Other MeshCore apps don't show the games, and the moves never appear as chat messages.

## Start a game

Open a channel, tap **+** next to the message box, then **Chess games**. The entry shows how many games and invites are open on that channel.

- **Challenge someone**: pick a person recently heard on this channel. Only a radio with that name can accept. Their phone shows a notification.
- **Post an open invite**: anyone on the channel can accept. If two people accept at the same time, the inviter's phone picks the first one it heard and tells everyone; the other person keeps watching.

Choose the **time per move** (no limit, 15 minutes, 1 hour (default), 6 hours, 1 day or 3 days) and **your colour** (random, white or black). Unanswered invites expire after a day. Tap your own invite to cancel it.

## Play

The board turns so that your pieces are at the bottom. Tap one of your pieces, then one of the marked squares. A promotion asks which piece you want.

- **Offer draw** / **Accept draw**. Making a move instead declines an offer.
- **Resign** asks first.
- **Claim win on time** appears when your opponent has gone more than 10 minutes past the time per move. Your phone times it from when it sent your last move; the 10 minutes allow for slow delivery. Other phones accept the claim once the time per move has passed since they heard that move.
- **Ask for update** gets a stuck game moving. While you wait after your own move, it sends that move again, and your opponent's phone answers with its move if you missed it. Otherwise it asks the players to send the latest move again. A player answers within a few seconds, at most once a minute per game.

If the radio doesn't confirm a move, the move stays on your board, since it may have gone out, and the game says so. Use **Ask for update** to send it again.

Checkmate, stalemate, not enough pieces to mate, the 50-move rule and repetition end the game on their own.

You get a notification when you're challenged, when it's your move, and when a game ends, unless the channel is muted or the game is open on screen. Notifications open the channel.

## Watch

Every game on the channel shows up under **Live games**. If you joined late, the board appears with the next move, because each move carries the whole position. Moves from before you joined show as "(missed)". Until you've heard how the game started, the players are marked as not confirmed; **Ask for update** fetches that. If your phone never heard the invite, the players stay marked as not confirmed, because nothing ties them to it.

Finished games stay in the list for a week. Tap **✕** to remove one sooner.

## How moves are sent

Each packet starts with a 5-byte header: app and packet kind, a random 2-byte game ID, and the 2-byte half-move number. Kinds are invite, accept, decline, move, resign, draw offer, draw accept, cancel, timeout claim, game info and request.

A move is 48 bytes or less, which fills four 16-byte encrypted blocks on air:

| Field | Bytes |
|---|---|
| Header | 5 |
| Move, as its index in the sorted list of legal moves | 1 |
| Chain value (see below) | 16 |
| Position after the move | ≤26 |

The position is an 8-byte map of occupied squares, 2 bytes for side to move, castling, en passant and the 50-move counter, then half a byte per piece.

Other packets: invite 55 bytes (87 for a challenge, with the name), accept 53, decline 37, resign, draw offer, draw accept, cancel and timeout claim 21 each, game info 122, request 6, with names of up to 31 bytes.

**Checking who moved.** Each player's phone makes a secret value and hashes it 512 times. Only the last hash is sent, in the invite or accept. Each later action reveals the hash one step back, which anyone can check by hashing it forward but nobody else can produce. A packet with a value that doesn't fit the player's chain is ignored. Each value counts once, and only after the ones before it: the first packet heard with a value uses it up, even when it doesn't change the game (a draw offer for a position you haven't seen yet, say), and values before it no longer count. If your opponent then needs a move again, their phone sends it with a new value. Player names are not checked; the chain is.

The inviter's first value after the commitment is kept for the game info, which says whose accept won. Anyone who heard the invite can check it came from the inviter, and works out the colours from the invite rather than taking the packet's word. If you accepted and the game info names someone else, you watch the game instead, and switch to playing if a later game info names you.

Players also check that the move gives the position in the packet. Spectators who missed moves take the position as it is. A draw accept only counts after a draw offer, and a timeout claim only when the game has a time per move and it has run out.

Your secret values stay on your phone, stored per radio with the rest of the game.
