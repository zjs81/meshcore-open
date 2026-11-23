# Chess

Play chess with someone on a channel, or watch other people's games. Moves go over the mesh as small channel data packets, so games suit a slow network: each move can take its time, and anyone on the channel can follow along.

## Requirements

- Companion firmware v1.15 or newer, on every radio that plays or watches. Older firmware can't send or receive channel data, and the games sheet says so.
- Everyone involved must be on the same channel (same key). Other MeshCore apps don't show the games, and the moves never appear as chat messages.

## Start a game

Open a channel, tap **⋮**, then **Chess games**. The menu shows how many games and invites are open on that channel.

- **Challenge someone**: pick a person recently heard on this channel. Only they can accept. Their phone shows a notification.
- **Post an open invite**: anyone on the channel can accept. If two people accept at the same time, the inviter's phone picks the first one it heard and tells everyone; the other person keeps watching.

Choose the **time per move** (no limit, 15 minutes, 1 hour (default), 6 hours, 1 day or 3 days) and **your colour** (random, white or black). Unanswered invites expire after a day. Tap your own invite to cancel it.

## Play

The board turns so that your pieces are at the bottom. Tap one of your pieces, then one of the marked squares. A promotion asks which piece you want.

- **Offer draw** / **Accept draw**. Making a move instead declines an offer.
- **Resign** asks first.
- **Claim win on time** appears when your opponent has gone more than 10 minutes past the time per move. Your phone times it from when it sent your last move; the 10 minutes allow for slow delivery.
- **Ask for update** asks the players to send the latest move again. Use it when a game looks stuck. A player answers within a few seconds, at most once a minute per game.

Checkmate, stalemate, not enough pieces to mate, the 50-move rule and repetition end the game on their own.

You get a notification when you're challenged, when it's your move, and when a game ends, unless the channel is muted. Notifications open the channel.

## Watch

Every game on the channel shows up under **Live games**. If you joined late, the board appears with the next move, because each move carries the whole position. Moves from before you joined show as "(missed)". Until you've heard how the game started, the players are marked as not confirmed; **Ask for update** fetches that.

Finished games stay in the list for a week. Tap **✕** to remove one sooner.

## How moves are sent

Each packet starts with a 4-byte header: app and packet kind, a random 2-byte game ID, and the half-move number. Kinds are invite, accept, decline, move, resign, draw offer, draw accept, cancel, timeout claim, game info and request.

A move is 49 bytes or less, which fills four 16-byte encrypted blocks on air:

| Field | Bytes |
|---|---|
| Header | 4 |
| Minutes since the game started | 2 |
| Move, as its index in the sorted list of legal moves | 1 |
| Chain value (see below) | 16 |
| Position after the move | ≤26 |

The position is an 8-byte map of occupied squares, 2 bytes for side to move, castling, en passant and the 50-move counter, then half a byte per piece.

**Checking who moved.** Each player's phone makes a secret value and hashes it 512 times. Only the last hash is sent, in the invite or accept. Each later action reveals the hash one step back, which anyone can check with a single hash but nobody else can produce. A packet with a value that doesn't fit the player's chain is ignored. If two different packets arrive with the same value, the first one heard counts. Player names are not checked; the chain is.

Players also check that the move gives the position in the packet. Spectators who missed moves take the position as it is.

Your secret values stay on your phone, stored per radio with the rest of the game.
