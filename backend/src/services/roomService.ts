import pool from '../config/db';
import redisClient from '../config/redis';
import {
  Room,
  RoomState,
  RoomMember,
  PlaybackSync,
  DjState,
  VetoState,
  Reaction,
  ReactionType,
  VibeState,
  SongPlayRecord,
  SessionEvent,
  MemberStats,
  Award,
  WrappedSummary,
} from '../types/room';

// ============================================================================
// ROOM MANAGEMENT
// ============================================================================

function generateRoomCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

export async function createRoom(
  name: string,
  hostId: string,
  isPublic: boolean = false
): Promise<Room> {
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = generateRoomCode();

    try {
      const result = await pool.query(
        `INSERT INTO rooms (code, name, host_id, is_public)
         VALUES ($1, $2, $3, $4)
         RETURNING id, code, name, host_id, is_public, created_at, updated_at`,
        [code, name, hostId, isPublic]
      );

      const row = result.rows[0];
      const room: Room = {
        id: row.id,
        code: row.code,
        name: row.name,
        hostId: row.host_id,
        isPublic: row.is_public,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      };

      await redisClient.hSet(`room:${code}`, {
        code: room.code,
        name: room.name,
        hostId: room.hostId,
        currentDjId: hostId,
        currentSongId: '',
        isPlaying: 'false',
        positionMs: '0',
      });

      await redisClient.expire(`room:${code}`, 86400);

      return room;
    } catch (err: any) {
      if (err.code === '23505') continue;
      throw err;
    }
  }
  throw new Error('Failed to generate a unique room code');
}

export async function findRoomByCode(code: string): Promise<Room | null> {
  const result = await pool.query(
    `SELECT id, code, name, host_id, is_public, created_at, updated_at
     FROM rooms WHERE code = $1`,
    [code]
  );

  if (result.rows.length === 0) return null;

  const row = result.rows[0];
  return {
    id: row.id,
    code: row.code,
    name: row.name,
    hostId: row.host_id,
    isPublic: row.is_public,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export async function getRoomState(code: string): Promise<RoomState | null> {
  const state = await redisClient.hGetAll(`room:${code}`);
  if (!state || !state.code) return null;

  const members = await redisClient.sMembers(`room:${code}:members`);
  const membersParsed: RoomMember[] = members.map((m) => JSON.parse(m));

  return {
    code: state.code,
    name: state.name,
    hostId: state.hostId,
    currentDjId: state.currentDjId || null,
    currentSongId: state.currentSongId || null,
    isPlaying: state.isPlaying === 'true',
    positionMs: parseInt(state.positionMs || '0', 10),
    members: membersParsed,
  };
}

export async function addMemberToRoom(
  code: string,
  member: RoomMember
): Promise<void> {
  await redisClient.sAdd(`room:${code}:members`, JSON.stringify(member));
  await redisClient.expire(`room:${code}`, 86400);
  await redisClient.expire(`room:${code}:members`, 86400);
}

export async function removeMemberFromRoom(
  code: string,
  socketId: string
): Promise<void> {
  const members = await redisClient.sMembers(`room:${code}:members`);
  for (const m of members) {
    const parsed: RoomMember = JSON.parse(m);
    if (parsed.socketId === socketId) {
      await redisClient.sRem(`room:${code}:members`, m);
      break;
    }
  }
}

export async function getPublicRooms(): Promise<Room[]> {
  const result = await pool.query(
    `SELECT id, code, name, host_id, is_public, created_at, updated_at
     FROM rooms ORDER BY created_at DESC LIMIT 50`
  );

  return result.rows.map((row) => ({
    id: row.id,
    code: row.code,
    name: row.name,
    hostId: row.host_id,
    isPublic: row.is_public,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }));
}

// ============================================================================
// PLAYBACK SYNC — Phase 1
// ============================================================================

export async function setPlaybackSync(
  code: string,
  sync: PlaybackSync
): Promise<void> {
  await redisClient.hSet(`room:${code}`, {
    currentSongId: sync.songId,
    isPlaying: sync.isPlaying ? 'true' : 'false',
    positionMs: sync.positionMs.toString(),
    startedAtMs: sync.startedAtMs.toString(),
  });
  await redisClient.expire(`room:${code}`, 86400);
}

export async function getPlaybackSync(
  code: string
): Promise<PlaybackSync | null> {
  const state = await redisClient.hGetAll(`room:${code}`);
  if (!state || !state.currentSongId) return null;

  return {
    songId: state.currentSongId,
    songTitle: state.songTitle || '',
    songArtist: state.songArtist || '',
    songUrl: state.songUrl || '',
    songCover: state.songCover || '',
    isPlaying: state.isPlaying === 'true',
    positionMs: parseInt(state.positionMs || '0', 10),
    startedAtMs: parseInt(state.startedAtMs || '0', 10),
    triggeredBy: state.triggeredBy || '',
  };
}

export async function clearPlaybackSync(code: string): Promise<void> {
  await redisClient.hSet(`room:${code}`, {
    currentSongId: '',
    isPlaying: 'false',
    positionMs: '0',
    startedAtMs: '0',
  });
}

export function calculateCurrentPosition(sync: PlaybackSync): number {
  if (!sync.isPlaying) return sync.positionMs;
  const elapsed = Date.now() - sync.startedAtMs;
  return sync.positionMs + elapsed;
}

// ============================================================================
// DJ BATON — Phase 2
// ============================================================================

const DEFAULT_MAX_SONGS_PER_SET = 3;

export async function setCurrentDj(
  code: string,
  djId: string,
  djUsername: string
): Promise<void> {
  await redisClient.hSet(`room:${code}`, {
    currentDjId: djId,
    currentDjUsername: djUsername,
    songsPlayedInSet: '0',
    maxSongsPerSet: DEFAULT_MAX_SONGS_PER_SET.toString(),
    batonPassedAt: Date.now().toString(),
  });
  await redisClient.expire(`room:${code}`, 86400);
}

export async function getDjState(code: string): Promise<DjState | null> {
  const state = await redisClient.hGetAll(`room:${code}`);
  if (!state || !state.currentDjId) return null;

  return {
    currentDjId: state.currentDjId,
    currentDjUsername: state.currentDjUsername || '',
    songsPlayedInSet: parseInt(state.songsPlayedInSet || '0', 10),
    maxSongsPerSet: parseInt(
      state.maxSongsPerSet || DEFAULT_MAX_SONGS_PER_SET.toString(),
      10
    ),
    batonPassedAt: parseInt(state.batonPassedAt || '0', 10),
  };
}

export async function incrementDjSongCount(
  code: string
): Promise<{ shouldPass: boolean; count: number; max: number }> {
  const state = await getDjState(code);
  if (!state) return { shouldPass: false, count: 0, max: 0 };

  const newCount = state.songsPlayedInSet + 1;
  await redisClient.hSet(`room:${code}`, {
    songsPlayedInSet: newCount.toString(),
  });

  return {
    shouldPass: newCount >= state.maxSongsPerSet,
    count: newCount,
    max: state.maxSongsPerSet,
  };
}

export async function resetDjSongCount(code: string): Promise<void> {
  await redisClient.hSet(`room:${code}`, { songsPlayedInSet: '0' });
}

export async function pickNextDj(
  code: string,
  excludeDjId: string
): Promise<RoomMember | null> {
  const members = await redisClient.sMembers(`room:${code}:members`);
  if (members.length < 2) return null;

  const parsed: RoomMember[] = members
    .map((m) => JSON.parse(m))
    .sort((a, b) => a.joinedAt - b.joinedAt);

  const currentIndex = parsed.findIndex((m) => m.userId === excludeDjId);
  const nextIndex =
    currentIndex < 0 ? 0 : (currentIndex + 1) % parsed.length;

  return parsed[nextIndex];
}

export async function setMaxSongsPerSet(
  code: string,
  maxSongs: number
): Promise<void> {
  await redisClient.hSet(`room:${code}`, {
    maxSongsPerSet: maxSongs.toString(),
  });
}

// ============================================================================
// VETO VOTING — Phase 3
// ============================================================================

const VETO_DURATION_MS = 30_000;
const VETO_THRESHOLD_PERCENT = 0.3;

export async function startVeto(
  code: string,
  songId: string,
  songTitle: string,
  proposedBy: string,
  proposedByUsername: string,
  totalMembers: number
): Promise<VetoState> {
  const now = Date.now();
  const threshold = Math.max(
    2,
    Math.ceil(totalMembers * VETO_THRESHOLD_PERCENT)
  );

  const veto: VetoState = {
    songId,
    songTitle,
    proposedBy,
    proposedByUsername,
    startedAt: now,
    expiresAt: now + VETO_DURATION_MS,
    threshold,
    currentVotes: 0,
    voters: [],
    isActive: true,
  };

  await redisClient.hSet(`room:${code}:veto`, {
    songId: veto.songId,
    songTitle: veto.songTitle,
    proposedBy: veto.proposedBy,
    proposedByUsername: veto.proposedByUsername,
    startedAt: veto.startedAt.toString(),
    expiresAt: veto.expiresAt.toString(),
    threshold: veto.threshold.toString(),
    currentVotes: '0',
    isActive: 'true',
  });

  await redisClient.del(`room:${code}:veto:voters`);
  await redisClient.expire(`room:${code}:veto`, 120);

  await castVetoVote(code, proposedBy);
  veto.currentVotes = 1;
  veto.voters = [proposedBy];

  return veto;
}

export async function castVetoVote(
  code: string,
  userId: string
): Promise<VetoState | null> {
  const veto = await getVetoState(code);
  if (!veto || !veto.isActive) return null;
  if (veto.expiresAt < Date.now()) return null;

  await redisClient.sAdd(`room:${code}:veto:voters`, userId);
  const voters = await redisClient.sMembers(`room:${code}:veto:voters`);

  await redisClient.hSet(`room:${code}:veto`, {
    currentVotes: voters.length.toString(),
  });

  return {
    ...veto,
    currentVotes: voters.length,
    voters,
  };
}

export async function getVetoState(code: string): Promise<VetoState | null> {
  const data = await redisClient.hGetAll(`room:${code}:veto`);
  if (!data || !data.songId) return null;
  if (data.isActive !== 'true') return null;

  const voters = await redisClient.sMembers(`room:${code}:veto:voters`);

  return {
    songId: data.songId,
    songTitle: data.songTitle || '',
    proposedBy: data.proposedBy || '',
    proposedByUsername: data.proposedByUsername || '',
    startedAt: parseInt(data.startedAt || '0', 10),
    expiresAt: parseInt(data.expiresAt || '0', 10),
    threshold: parseInt(data.threshold || '2', 10),
    currentVotes: voters.length,
    voters,
    isActive: data.isActive === 'true',
  };
}

export async function clearVeto(code: string): Promise<void> {
  await redisClient.del(`room:${code}:veto`);
  await redisClient.del(`room:${code}:veto:voters`);
}
// ============================================================================
// VIBE CHECK & REACTIONS — Phase 4
// ============================================================================

const VIBE_WINDOW_MS = 60_000;  // 60-second rolling window

/**
 * Stores a reaction for the current song in Redis.
 * Reactions expire in 5 minutes (per song).
 */
export async function addReaction(
  code: string,
  reaction: Reaction
): Promise<void> {
  const key = `room:${code}:reactions:${reaction.songId}`;
  await redisClient.lPush(key, JSON.stringify(reaction));
  await redisClient.lTrim(key, 0, 99); // Keep last 100
  await redisClient.expire(key, 300);

  // Increment the vibe counter for this song
  const vibeKey = `room:${code}:vibe:${reaction.songId}`;
  await redisClient.hIncrBy(vibeKey, reaction.type, 1);
  await redisClient.hSet(vibeKey, 'lastUpdated', Date.now().toString());
  await redisClient.expire(vibeKey, 300);
}

/**
 * Gets the vibe state for a specific song.
 */
export async function getVibeState(
  code: string,
  songId: string
): Promise<VibeState> {
  const vibeKey = `room:${code}:vibe:${songId}`;
  const data = await redisClient.hGetAll(vibeKey);

  const counts = {
    love: parseInt(data.love || '0', 10),
    fire: parseInt(data.fire || '0', 10),
    laugh: parseInt(data.laugh || '0', 10),
    party: parseInt(data.party || '0', 10),
    wow: parseInt(data.wow || '0', 10),
  };

  const total =
    counts.love + counts.fire + counts.laugh + counts.party + counts.wow;

  // Energy formula: weighted sum
  // fire + party weigh more (they're hype reactions)
  // love + laugh are neutral
  // wow is small
  const weighted =
    counts.fire * 25 +
    counts.party * 22 +
    counts.wow * 12 +
    counts.laugh * 10 +
    counts.love * 8;

  const energy = Math.min(100, Math.round(weighted));

  return {
    energy,
    reactionCounts: counts,
    totalReactions: total,
    lastUpdated: parseInt(data.lastUpdated || Date.now().toString(), 10),
  };
}

/**
 * Gets recent reactions for a song (for the ticker feed).
 */
export async function getRecentReactions(
  code: string,
  songId: string,
  limit: number = 10
): Promise<Reaction[]> {
  const key = `room:${code}:reactions:${songId}`;
  const items = await redisClient.lRange(key, 0, limit - 1);
  return items.map((i) => JSON.parse(i));
}

/**
 * Clears reaction data (when room ends).
 */
export async function clearReactions(code: string): Promise<void> {
  const keys = await redisClient.keys(`room:${code}:vibe:*`);
  const reactionKeys = await redisClient.keys(`room:${code}:reactions:*`);
  const all = [...keys, ...reactionKeys];
  if (all.length > 0) {
    await redisClient.del(all);
  }
}

// ============================================================================
// LIVE WRAPPED — Phase 5
// ============================================================================

/**
 * Initialize session tracking when a room is created.
 */
export async function initSession(code: string): Promise<void> {
  await redisClient.hSet(`room:${code}:session`, {
    startedAt: Date.now().toString(),
    endedAt: '0',
  });
  await redisClient.expire(`room:${code}:session`, 86400);
}

/**
 * Track a song play event.
 */
export async function trackSongPlayed(
  code: string,
  record: SongPlayRecord
): Promise<void> {
  await redisClient.lPush(`room:${code}:session:songs`, JSON.stringify(record));
  await redisClient.expire(`room:${code}:session:songs`, 86400);
}

/**
 * Track any session event (for audit + stats).
 */
export async function trackSessionEvent(
  code: string,
  event: SessionEvent
): Promise<void> {
  await redisClient.lPush(
    `room:${code}:session:events`,
    JSON.stringify(event)
  );
  await redisClient.lTrim(`room:${code}:session:events`, 0, 499);
  await redisClient.expire(`room:${code}:session:events`, 86400);
}

/**
 * Get session start time.
 */
export async function getSessionStart(code: string): Promise<number> {
  const data = await redisClient.hGetAll(`room:${code}:session`);
  return parseInt(data.startedAt || Date.now().toString(), 10);
}

/**
 * Get all songs played in this session.
 */
export async function getSessionSongs(code: string): Promise<SongPlayRecord[]> {
  const items = await redisClient.lRange(`room:${code}:session:songs`, 0, -1);
  return items.map((i) => JSON.parse(i)).reverse();
}

/**
 * Aggregate member stats from session events.
 */
async function computeMemberStats(
  code: string,
  members: RoomMember[]
): Promise<MemberStats[]> {
  const events = await redisClient.lRange(
    `room:${code}:session:events`,
    0,
    -1
  );
  const parsed: SessionEvent[] = events.map((e) => JSON.parse(e));

  const statsMap = new Map<string, MemberStats>();

  for (const m of members) {
    statsMap.set(m.userId, {
      userId: m.userId,
      username: m.username,
      songsPlayed: 0,
      reactionsSent: 0,
      vetoesProposed: 0,
      vetoesVoted: 0,
      timeAsDj: 0,
      joinedAt: m.joinedAt,
    });
  }

  // Process events
  for (let i = 0; i < parsed.length; i++) {
    const e = parsed[i];
    const stat = statsMap.get(e.userId);
    if (!stat) continue;

    switch (e.type) {
      case 'play':
        stat.songsPlayed++;
        break;
      case 'reaction':
        stat.reactionsSent++;
        break;
      case 'veto':
        if (e.metadata?.role === 'proposer') stat.vetoesProposed++;
        if (e.metadata?.role === 'voter') stat.vetoesVoted++;
        break;
    }
  }

  return Array.from(statsMap.values());
}

/**
 * Generate awards based on session data.
 */
function computeAwards(
  members: MemberStats[],
  songs: SongPlayRecord[],
  reactionCountsBySong: Map<string, number>
): Award[] {
  const awards: Award[] = [];

  // Award 1: Most songs played (Real DJ)
  if (members.length > 0) {
    const top = [...members].sort((a, b) => b.songsPlayed - a.songsPlayed)[0];
    if (top.songsPlayed > 0) {
      awards.push({
        type: 'top_dj',
        emoji: '🎧',
        title: 'Top DJ',
        description: `Played the most songs`,
        winnerUserId: top.userId,
        winnerUsername: top.username,
        value: top.songsPlayed,
      });
    }
  }

  // Award 2: Reaction King
  if (members.length > 0) {
    const top = [...members].sort(
      (a, b) => b.reactionsSent - a.reactionsSent
    )[0];
    if (top.reactionsSent > 0) {
      awards.push({
        type: 'reaction_king',
        emoji: '💫',
        title: 'Reaction King',
        description: 'Sent the most reactions',
        winnerUserId: top.userId,
        winnerUsername: top.username,
        value: top.reactionsSent,
      });
    }
  }

  // Award 3: Veto Master
  if (members.length > 0) {
    const top = [...members].sort(
      (a, b) => b.vetoesProposed - a.vetoesProposed
    )[0];
    if (top.vetoesProposed > 0) {
      awards.push({
        type: 'veto_master',
        emoji: '🗳️',
        title: 'Veto Master',
        description: 'Proposed the most vetoes',
        winnerUserId: top.userId,
        winnerUsername: top.username,
        value: top.vetoesProposed,
      });
    }
  }

  // Award 4: Loudest Listener
  if (members.length > 0) {
    const top = [...members].sort(
      (a, b) => b.vetoesVoted - a.vetoesVoted
    )[0];
    if (top.vetoesVoted > 0) {
      awards.push({
        type: 'democracy',
        emoji: '✊',
        title: 'Voice of the People',
        description: 'Voted on the most vetoes',
        winnerUserId: top.userId,
        winnerUsername: top.username,
        value: top.vetoesVoted,
      });
    }
  }

  // Award 5: Most Obscure Pick (last song played by anyone)
  if (songs.length > 2) {
    const lastSong = songs[songs.length - 1];
    awards.push({
      type: 'obscure',
      emoji: '🎲',
      title: 'Deep Cut',
      description: `Last song played: "${lastSong.songTitle}"`,
      winnerUserId: lastSong.playedByUserId,
      winnerUsername: lastSong.playedByUsername,
    });
  }

  return awards;
}

/**
 * Build the full Wrapped summary.
 */
export async function generateWrapped(
  code: string
): Promise<WrappedSummary | null> {
  const room = await findRoomByCode(code);
  if (!room) return null;

  const roomState = await getRoomState(code);
  const members = roomState?.members || [];

  const sessionData = await redisClient.hGetAll(`room:${code}:session`);
  const startedAt = parseInt(sessionData.startedAt || Date.now().toString(), 10);
  const endedAt = Date.now();

  const songs = await getSessionSongs(code);
  const memberStats = await computeMemberStats(code, members);

  // Compute reaction totals per song
  const reactionCountsBySong = new Map<string, number>();
  let totalReactions = 0;
  for (const s of songs) {
    const vibe = await getVibeState(code, s.songId);
    reactionCountsBySong.set(s.songId, vibe.totalReactions);
    totalReactions += vibe.totalReactions;
  }

  // Find top song (most reactions)
  let topSong: SongPlayRecord | null = null;
  let topSongReactions = 0;
  for (const s of songs) {
    const count = reactionCountsBySong.get(s.songId) || 0;
    if (count > topSongReactions) {
      topSongReactions = count;
      topSong = s;
    }
  }

  // Count vetoes (from events)
  const events = await redisClient.lRange(
    `room:${code}:session:events`,
    0,
    -1
  );
  const parsedEvents: SessionEvent[] = events.map((e) => JSON.parse(e));
  const totalVetoes = parsedEvents.filter((e) => e.type === 'veto').length;
  const totalBatonPasses = parsedEvents.filter(
    (e) => e.type === 'baton_pass'
  ).length;

  const awards = computeAwards(memberStats, songs, reactionCountsBySong);

  return {
    roomCode: room.code,
    roomName: room.name,
    startedAt,
    endedAt,
    durationMs: endedAt - startedAt,
    totalSongs: songs.length,
    totalReactions,
    totalVetoes,
    totalBatonPasses,
    memberCount: members.length,
    songsPlayed: songs,
    topSong,
    topSongReactions,
    mostVetoedSong: null, // Future enhancement
    mostVetoedCount: 0,
    memberStats,
    awards,
  };
}

/**
 * Clear session data after wrapped is generated (or room is closed).
 */
export async function clearSession(code: string): Promise<void> {
  const keys = await redisClient.keys(`room:${code}:session*`);
  const vibeKeys = await redisClient.keys(`room:${code}:vibe:*`);
  const reactionKeys = await redisClient.keys(`room:${code}:reactions:*`);
  const all = [...keys, ...vibeKeys, ...reactionKeys];
  if (all.length > 0) {
    await redisClient.del(all);
  }
}

// ============================================================================
// LIVE SEARCH (Idea 1 & 4) — Phase 6
// ============================================================================

export interface LiveSearchResult {
  rooms: Array<{
    code: string;
    name: string;
    currentSongTitle: string;
    currentDjUsername: string;
    listenerCount: number;
    isPlaying: boolean;
  }>;
  users: Array<{
    userId: string;
    username: string;
    roomCode: string;
    roomName: string;
  }>;
}

export async function searchLive(query: string): Promise<LiveSearchResult> {
  const q = query.toLowerCase().trim();
  const emptyResult: LiveSearchResult = { rooms: [], users: [] };
  if (q.length < 2) return emptyResult;

  // 1. Get all public rooms from PostgreSQL
  const publicRooms = await getPublicRooms();
  
  const matchingRooms: LiveSearchResult['rooms'] = [];
  const matchingUsers: LiveSearchResult['users'] = [];

  // 2. For each public room, get Redis state and members
  for (const room of publicRooms) {
    const state = await getRoomState(room.code);
    if (!state) continue;

    const playback = await getPlaybackSync(room.code);
    const djState = await getDjState(room.code);

    const roomNameMatch = room.name.toLowerCase().includes(q);
    const songMatch = playback?.songTitle.toLowerCase().includes(q) || 
                      playback?.songArtist.toLowerCase().includes(q);
    
    // Check members for username matches
    let hasMatchingMember = false;
    for (const member of state.members) {
      if (member.username.toLowerCase().includes(q)) {
        hasMatchingMember = true;
        matchingUsers.push({
          userId: member.userId,
          username: member.username,
          roomCode: room.code,
          roomName: room.name,
        });
      }
    }

    // If room name, song, or a member matches, add the room
    if (roomNameMatch || songMatch || hasMatchingMember) {
      matchingRooms.push({
        code: room.code,
        name: room.name,
        currentSongTitle: playback?.songTitle || 'No song playing',
        currentDjUsername: djState?.currentDjUsername || 'Unknown',
        listenerCount: state.members.length,
        isPlaying: playback?.isPlaying || false,
      });
    }
  }

  return {
    rooms: matchingRooms.slice(0, 10), // Limit to 10 results
    users: matchingUsers.slice(0, 10),
  };
}

// ============================================================================
// EXPLORE / DISCOVER — Phase 6
// ============================================================================

export interface ExploreData {
  liveRooms: Array<{
    code: string;
    name: string;
    currentSongTitle: string;
    currentSongCover: string;
    currentDjUsername: string;
    listenerCount: number;
    isPlaying: boolean;
  }>;
  totalActiveListeners: number;
}

/**
 * Returns live public rooms with active listeners.
 * Used for the Explore section on the search screen.
 */
export async function getExploreData(): Promise<ExploreData> {
  const publicRooms = await getPublicRooms();

  const liveRooms: ExploreData['liveRooms'] = [];
  let totalActiveListeners = 0;

  for (const room of publicRooms.slice(0, 20)) {
    const state = await getRoomState(room.code);
    if (!state || state.members.length === 0) continue;

    totalActiveListeners += state.members.length;

    const playback = await getPlaybackSync(room.code);
    const djState = await getDjState(room.code);

    // Only include rooms that have activity (playing something)
    if (!playback?.songId) continue;

    liveRooms.push({
      code: room.code,
      name: room.name,
      currentSongTitle: playback.songTitle || 'Unknown',
      currentSongCover: playback.songCover || '',
      currentDjUsername: djState?.currentDjUsername || 'Unknown',
      listenerCount: state.members.length,
      isPlaying: playback.isPlaying,
    });
  }

  // Sort by listener count (most popular first)
  liveRooms.sort((a, b) => b.listenerCount - a.listenerCount);

  return {
    liveRooms: liveRooms.slice(0, 10),
    totalActiveListeners,
  };
}
