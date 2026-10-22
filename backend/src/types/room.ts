export interface Room {
  id: number;
  code: string;
  name: string;
  hostId: string;
  isPublic: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface RoomState {
  code: string;
  name: string;
  hostId: string;
  currentDjId: string | null;
  currentSongId: string | null;
  isPlaying: boolean;
  positionMs: number;
  members: RoomMember[];
}

export interface RoomMember {
  socketId: string;
  userId: string;
  username: string;
  joinedAt: number;
}

export interface PlaybackSync {
  songId: string;
  songTitle: string;
  songArtist: string;
  songUrl: string;
  songCover: string;
  isPlaying: boolean;
  positionMs: number;
  // The wall-clock time (ms since epoch) when playback started.
  // Every client uses this to calculate the true current position.
  startedAtMs: number;
  // Who triggered this (DJ or a specific user)
  triggeredBy: string;
}

// ============================================================================
// DJ Baton Types — Phase 2
// ============================================================================

export interface DjState {
  currentDjId: string;
  currentDjUsername: string;
  songsPlayedInSet: number;
  maxSongsPerSet: number;
  batonPassedAt: number;
}

export interface BatonPassedEvent {
  previousDjId: string;
  previousDjUsername: string;
  newDjId: string;
  newDjUsername: string;
  reason: 'manual' | 'auto' | 'dj_left';
  passedAt: number;
}

// ============================================================================
// Veto Voting Types — Phase 3
// ============================================================================

export interface VetoState {
  songId: string;
  songTitle: string;
  proposedBy: string;
  proposedByUsername: string;
  startedAt: number;
  expiresAt: number;
  threshold: number;      // Number of votes needed
  currentVotes: number;    // Votes so far
  voters: string[];        // User IDs who voted
  isActive: boolean;
}

export interface VetoResult {
  passed: boolean;         // Did the veto succeed?
  songId: string;
  voteCount: number;
  threshold: number;
  reason: 'passed' | 'expired' | 'cancelled';
}

// ============================================================================
// Vibe Check & Reactions — Phase 4
// ============================================================================

export type ReactionType = 'love' | 'fire' | 'laugh' | 'party' | 'wow';

export interface Reaction {
  id: string;                    // unique ID for animation dedup
  type: ReactionType;            // emoji type
  userId: string;
  username: string;
  songId: string;
  timestamp: number;
}

export interface VibeState {
  // 0 = chill, 100 = hype
  energy: number;
  reactionCounts: {
    love: number;
    fire: number;
    laugh: number;
    party: number;
    wow: number;
  };
  totalReactions: number;
  lastUpdated: number;
}

export const REACTION_EMOJI: Record<ReactionType, string> = {
  love: '❤️',
  fire: '🔥',
  laugh: '😂',
  party: '🎉',
  wow: '😮',
};

// ============================================================================
// Live Wrapped — Phase 5
// ============================================================================

export interface SongPlayRecord {
  songId: string;
  songTitle: string;
  songArtist: string;
  songCover: string;
  playedByUserId: string;
  playedByUsername: string;
  playedAt: number;
}

export interface SessionEvent {
  type: 'play' | 'reaction' | 'veto' | 'baton_pass' | 'member_join' | 'member_leave';
  userId: string;
  username: string;
  timestamp: number;
  metadata?: any;
}

export interface MemberStats {
  userId: string;
  username: string;
  songsPlayed: number;
  reactionsSent: number;
  vetoesProposed: number;
  vetoesVoted: number;
  timeAsDj: number;      // ms
  joinedAt: number;
}

export interface Award {
  type: string;
  emoji: string;
  title: string;
  description: string;
  winnerUserId?: string;
  winnerUsername?: string;
  value?: any;
}

export interface WrappedSummary {
  roomCode: string;
  roomName: string;
  startedAt: number;
  endedAt: number;
  durationMs: number;
  totalSongs: number;
  totalReactions: number;
  totalVetoes: number;
  totalBatonPasses: number;
  memberCount: number;
  songsPlayed: SongPlayRecord[];
  topSong: SongPlayRecord | null;
  topSongReactions: number;
  mostVetoedSong: SongPlayRecord | null;
  mostVetoedCount: number;
  memberStats: MemberStats[];
  awards: Award[];
}