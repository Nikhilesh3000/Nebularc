import { Server, Socket } from 'socket.io';
import {
  createRoom,
  findRoomByCode,
  getRoomState,
  addMemberToRoom,
  removeMemberFromRoom,
  setPlaybackSync,
  getPlaybackSync,
  calculateCurrentPosition,
  setCurrentDj,
  getDjState,
  incrementDjSongCount,
  resetDjSongCount,
  pickNextDj,
  startVeto,
  castVetoVote,
  getVetoState,
  clearVeto,
  addReaction,
  getVibeState,
  getRecentReactions,
  initSession,
  trackSongPlayed,
  trackSessionEvent,
  getSessionStart,
  generateWrapped,
  clearSession,
  searchLive,
  getExploreData,
} from '../services/roomService';
import { PlaybackSync, BatonPassedEvent, VetoResult, Reaction, ReactionType, SongPlayRecord, SessionEvent,} from '../types/room';
import redisClient from '../config/redis';

export function registerRoomHandlers(io: Server, socket: Socket) {
  socket.on('create_room', async (payload: {
    name: string;
    userId: string;
    username: string;
    isPublic?: boolean;
  }) => {
    console.log('📥 Received create_room:', payload);
    try {
      const room = await createRoom(
        payload.name,
        payload.userId,
        payload.isPublic || false
      );
       await setCurrentDj(room.code, payload.userId, payload.username);
             // Initialize session tracking
      await initSession(room.code);

      const member = {
        socketId: socket.id,
        userId: payload.userId,
        username: payload.username,
        joinedAt: Date.now(),
      };

      await addMemberToRoom(room.code, member);
      socket.join(room.code);

      const state = await getRoomState(room.code);

      socket.emit('room_created', {
        success: true,
        room: { ...room, ...state },
      });

      console.log(`🏠 Room created: ${room.code} by ${payload.username}`);
    } catch (err) {
      console.error('❌ Error creating room:', err);
      socket.emit('room_error', { message: 'Failed to create room' });
    }
  });

  socket.on('join_room', async (payload: {
    code: string;
    userId: string;
    username: string;
  }) => {
    console.log('📥 Received join_room:', payload);
    try {
      const room = await findRoomByCode(payload.code);

      if (!room) {
        socket.emit('room_error', { message: 'Room not found' });
        return;
      }

      const member = {
        socketId: socket.id,
        userId: payload.userId,
        username: payload.username,
        joinedAt: Date.now(),
      };

      await addMemberToRoom(room.code, member);
      socket.join(room.code);

      const state = await getRoomState(room.code);
      const djState = await getDjState(room.code);
      if (!djState || !djState.currentDjId) {
        await setCurrentDj(room.code, payload.userId, payload.username);
      }

      socket.emit('room_joined', { success: true, room: state });
      socket.to(room.code).emit('member_joined', {
        member,
        members: state?.members,
      });

      console.log(`👤 ${payload.username} joined room ${room.code}`);
    } catch (err) {
      console.error('❌ Error joining room:', err);
      socket.emit('room_error', { message: 'Failed to join room' });
    }
  });

  socket.on('leave_room', async (payload: { code: string }) => {
    try {
      await removeMemberFromRoom(payload.code, socket.id);
            // If the leaving member was the DJ, pass the baton
      const djState = await getDjState(payload.code);
      if (djState && djState.currentDjId) {
        const members = await redisClient.sMembers(`room:${payload.code}:members`);
        const memberLeft = !members.some((m) => {
          const parsed = JSON.parse(m);
          return parsed.userId === djState.currentDjId;
        });

        if (memberLeft) {
          const nextDj = await pickNextDj(payload.code, djState.currentDjId);
          if (nextDj) {
            await setCurrentDj(payload.code, nextDj.userId, nextDj.username);
            io.to(payload.code).emit('baton_passed', {
              previousDjId: djState.currentDjId,
              previousDjUsername: djState.currentDjUsername,
              newDjId: nextDj.userId,
              newDjUsername: nextDj.username,
              reason: 'dj_left',
              passedAt: Date.now(),
            });
            console.log(`🎺 Baton passed (DJ left) to ${nextDj.username}`);
          }
        }
      }
      socket.leave(payload.code);

      const state = await getRoomState(payload.code);
      io.to(payload.code).emit('member_left', {
        socketId: socket.id,
        members: state?.members,
      });
    } catch (err) {
      console.error('Error leaving room:', err);
    }
  });

  socket.on('disconnecting', async (payload: { code: string }) => {
    const rooms = Array.from(socket.rooms).filter((r) => r !== socket.id);

    for (const code of rooms) {
      try {
        await removeMemberFromRoom(code, socket.id);
              // If the leaving member was the DJ, pass the baton
      const djState = await getDjState(payload.code);
      if (djState && djState.currentDjId) {
        const members = await redisClient.sMembers(`room:${payload.code}:members`);
        const memberLeft = !members.some((m) => {
          const parsed = JSON.parse(m);
          return parsed.userId === djState.currentDjId;
        });

        if (memberLeft) {
          const nextDj = await pickNextDj(payload.code, djState.currentDjId);
          if (nextDj) {
            await setCurrentDj(payload.code, nextDj.userId, nextDj.username);
            io.to(payload.code).emit('baton_passed', {
              previousDjId: djState.currentDjId,
              previousDjUsername: djState.currentDjUsername,
              newDjId: nextDj.userId,
              newDjUsername: nextDj.username,
              reason: 'dj_left',
              passedAt: Date.now(),
            });
            console.log(`🎺 Baton passed (DJ left) to ${nextDj.username}`);
          }
        }
      }
        const state = await getRoomState(code);
        io.to(code).emit('member_left', {
          socketId: socket.id,
          members: state?.members,
        });
      } catch (err) {
        console.error('Error during cleanup:', err);
      }
    }
  });

  
  /**
   * DJ plays a song. Everyone in the room should sync to it.
   */
  socket.on(
    'sync_play',
    async (payload: {
      code: string;
      songId: string;
      songTitle: string;
      songArtist: string;
      songUrl: string;
      songCover: string;
      userId: string;
    }) => {
      console.log('📥 sync_play:', payload);

      try {
        const now = Date.now();
        const sync: PlaybackSync = {
          songId: payload.songId,
          songTitle: payload.songTitle,
          songArtist: payload.songArtist,
          songUrl: payload.songUrl,
          songCover: payload.songCover,
          isPlaying: true,
          positionMs: 0,
          startedAtMs: now,
          triggeredBy: payload.userId,
        };

                await setPlaybackSync(payload.code, sync);
                await clearVeto(payload.code);

        // Broadcast to EVERYONE in the room (including sender)
        io.to(payload.code).emit('sync_play', sync);

        console.log(`🎵 Sync play in room ${payload.code}: ${payload.songTitle}`);
                // Track song in session
        const songRecord: SongPlayRecord = {
          songId: payload.songId,
          songTitle: payload.songTitle,
          songArtist: payload.songArtist,
          songCover: payload.songCover,
          playedByUserId: payload.userId,
          playedByUsername:
            (await getDjState(payload.code))?.currentDjUsername || 'Unknown',
          playedAt: Date.now(),
        };
        await trackSongPlayed(payload.code, songRecord);
        await trackSessionEvent(payload.code, {
          type: 'play',
          userId: payload.userId,
          username: songRecord.playedByUsername,
          timestamp: Date.now(),
        });

        // ---- DJ Baton auto-pass logic ----
        const result = await incrementDjSongCount(payload.code);
        
        // Send updated DJ state to everyone
        const djState = await getDjState(payload.code);
        io.to(payload.code).emit('dj_state_updated', djState);

        console.log(`🎧 DJ set: ${result.count}/${result.max} songs`);

        if (result.shouldPass) {
          // Time to pass the baton
          const nextDj = await pickNextDj(payload.code, payload.userId);
          if (nextDj) {
            const previousDjState = await getDjState(payload.code);
            
            await setCurrentDj(
              payload.code,
              nextDj.userId,
              nextDj.username
            );

            const batonEvent: BatonPassedEvent = {
              previousDjId: payload.userId,
              previousDjUsername: previousDjState?.currentDjUsername || '',
              newDjId: nextDj.userId,
              newDjUsername: nextDj.username,
              reason: 'auto',
              passedAt: Date.now(),
            };

            io.to(payload.code).emit('baton_passed', batonEvent);
        await trackSessionEvent(payload.code, {
          type: 'baton_pass',
          userId: payload.userId,
          username: djState.currentDjUsername,
          timestamp: Date.now(),
          metadata: { to: nextDj.userId, reason: 'manual' },
        });
            console.log(`🎺 Baton auto-passed to ${nextDj.username}`);
          }
        }
      } catch (err) {
        console.error('❌ sync_play error:', err);
      }
    }
  );

  /**
   * DJ pauses the current song.
   */
  socket.on(
    'sync_pause',
    async (payload: { code: string; positionMs: number }) => {
      try {
        const current = await getPlaybackSync(payload.code);
        if (!current) return;

        const updated: PlaybackSync = {
          ...current,
          isPlaying: false,
          positionMs: payload.positionMs,
          startedAtMs: Date.now(),
        };

        await setPlaybackSync(payload.code, updated);
        io.to(payload.code).emit('sync_pause', updated);

        console.log(`⏸️ Sync pause in room ${payload.code}`);
      } catch (err) {
        console.error('❌ sync_pause error:', err);
      }
    }
  );

  /**
   * DJ resumes playback.
   */
  socket.on(
    'sync_resume',
    async (payload: { code: string; positionMs: number }) => {
      try {
        const current = await getPlaybackSync(payload.code);
        if (!current) return;

        const updated: PlaybackSync = {
          ...current,
          isPlaying: true,
          positionMs: payload.positionMs,
          startedAtMs: Date.now(),
        };

        await setPlaybackSync(payload.code, updated);
        io.to(payload.code).emit('sync_resume', updated);

        console.log(`▶️ Sync resume in room ${payload.code}`);
      } catch (err) {
        console.error('❌ sync_resume error:', err);
      }
    }
  );

  /**
   * DJ seeks to a position.
   */
  socket.on(
    'sync_seek',
    async (payload: { code: string; positionMs: number }) => {
      try {
        const current = await getPlaybackSync(payload.code);
        if (!current) return;

        const updated: PlaybackSync = {
          ...current,
          positionMs: payload.positionMs,
          startedAtMs: Date.now(),
        };

        await setPlaybackSync(payload.code, updated);
        io.to(payload.code).emit('sync_seek', updated);

        console.log(`⏩ Sync seek in room ${payload.code}`);
      } catch (err) {
        console.error('❌ sync_seek error:', err);
      }
    }
  );

  /**
   * A late-joiner asks "what's currently playing? I want to sync in."
   */
  socket.on('sync_request', async (payload: { code: string }) => {
    try {
      const current = await getPlaybackSync(payload.code);
      if (!current) {
        socket.emit('sync_state', null);
        return;
      }

      // Calculate the true current position (with elapsed time)
      const truePosition = calculateCurrentPosition(current);

      socket.emit('sync_state', {
        ...current,
        positionMs: truePosition,
        startedAtMs: Date.now(),
      });

      console.log(`🔄 Sync state sent to ${socket.id} for room ${payload.code}`);
    } catch (err) {
      console.error('❌ sync_request error:', err);
    }
  });

    // ==========================================================================
  // DJ Baton — Phase 2
  // ==========================================================================

  /**
   * DJ manually passes the baton.
   */
  socket.on(
    'pass_baton',
    async (payload: { code: string; userId: string }) => {
      try {
        const djState = await getDjState(payload.code);
        if (!djState) return;

        // Only current DJ can pass
        if (djState.currentDjId !== payload.userId) {
          socket.emit('room_error', {
            message: 'Only the current DJ can pass the baton',
          });
          return;
        }

        const nextDj = await pickNextDj(payload.code, payload.userId);
        if (!nextDj) {
          socket.emit('room_error', {
            message: 'No other listeners to pass to',
          });
          return;
        }

        await setCurrentDj(payload.code, nextDj.userId, nextDj.username);

        const batonEvent: BatonPassedEvent = {
          previousDjId: payload.userId,
          previousDjUsername: djState.currentDjUsername,
          newDjId: nextDj.userId,
          newDjUsername: nextDj.username,
          reason: 'manual',
          passedAt: Date.now(),
        };

        io.to(payload.code).emit('baton_passed', batonEvent);
        console.log(`🎺 Baton manually passed to ${nextDj.username}`);
      } catch (err) {
        console.error('❌ pass_baton error:', err);
      }
    }
  );

  /**
   * Get the current DJ state for the room.
   */
  socket.on('dj_state_request', async (payload: { code: string }) => {
    try {
      const djState = await getDjState(payload.code);
      socket.emit('dj_state_updated', djState);
    } catch (err) {
      console.error('❌ dj_state_request error:', err);
    }
  });

    // ==========================================================================
  // Veto Voting — Phase 3
  // ==========================================================================

  /**
   * A listener proposes a veto on the current song.
   */
  socket.on(
    'propose_veto',
    async (payload: {
      code: string;
      userId: string;
      username: string;
    }) => {
      console.log('📥 propose_veto:', payload);

      try {
        // Check if a veto already exists
        const existing = await getVetoState(payload.code);
        if (existing && existing.isActive) {
          socket.emit('room_error', {
            message: 'A veto is already in progress',
          });
          return;
        }

        // Get the current song
        const playback = await getPlaybackSync(payload.code);
        if (!playback || !playback.songId) {
          socket.emit('room_error', {
            message: 'No song is currently playing',
          });
          return;
        }

        // Get room member count for threshold calculation
        const roomState = await getRoomState(payload.code);
        if (!roomState) {
          socket.emit('room_error', { message: 'Room not found' });
          return;
        }

        // Don't allow DJ to propose veto (they can just skip)
        const djState = await getDjState(payload.code);
        if (djState && djState.currentDjId === payload.userId) {
          socket.emit('room_error', {
            message: 'The DJ can skip songs directly',
          });
          return;
        }

        const veto = await startVeto(
          payload.code,
          playback.songId,
          playback.songTitle,
          payload.userId,
          payload.username,
          roomState.members.length
        );

        // Broadcast to everyone
        io.to(payload.code).emit('veto_started', veto);
        console.log(
          `🗳️ Veto started in ${payload.code}: "${playback.songTitle}" by ${payload.username}`
        );
      } catch (err) {
        console.error('❌ propose_veto error:', err);
      }
    }
  );

  /**
   * A listener adds their vote to the active veto.
   */
  socket.on(
    'vote_veto',
    async (payload: { code: string; userId: string }) => {
      try {
        const veto = await getVetoState(payload.code);
        if (!veto || !veto.isActive) {
          socket.emit('room_error', { message: 'No active veto' });
          return;
        }

        // Check if expired
        if (veto.expiresAt < Date.now()) {
          await clearVeto(payload.code);
          io.to(payload.code).emit('veto_result', {
            passed: false,
            songId: veto.songId,
            voteCount: veto.currentVotes,
            threshold: veto.threshold,
            reason: 'expired',
          });
          return;
        }

        const updated = await castVetoVote(payload.code, payload.userId);
        if (!updated) {
          socket.emit('room_error', { message: 'Veto no longer active' });
          return;
        }

         await trackSessionEvent(payload.code, {
          type: 'veto',
          userId: payload.userId,
          username: '',
          timestamp: Date.now(),
          metadata: { role: 'voter' },
        });

        // Broadcast updated vote count
        io.to(payload.code).emit('veto_updated', updated);
        console.log(
          `🗳️ Veto vote in ${payload.code}: ${updated.currentVotes}/${updated.threshold}`
        );

        // Check if threshold reached
        if (updated.currentVotes >= updated.threshold) {
          // Veto passed!
          await clearVeto(payload.code);

          const result: VetoResult = {
            passed: true,
            songId: updated.songId,
            voteCount: updated.currentVotes,
            threshold: updated.threshold,
            reason: 'passed',
          };

          io.to(payload.code).emit('veto_result', result);
          console.log(
            `✅ Veto PASSED in ${payload.code}: "${updated.songTitle}" skipped by vote`
          );
        }
      } catch (err) {
        console.error('❌ vote_veto error:', err);
      }
    }
  );

  /**
   * Manually cancel/clear a veto (e.g., timer expired).
   */
  socket.on(
    'clear_veto',
    async (payload: { code: string }) => {
      try {
        const veto = await getVetoState(payload.code);
        if (!veto) return;

        await clearVeto(payload.code);
        io.to(payload.code).emit('veto_result', {
          passed: false,
          songId: veto.songId,
          voteCount: veto.currentVotes,
          threshold: veto.threshold,
          reason: 'expired',
        });
      } catch (err) {
        console.error('❌ clear_veto error:', err);
      }
    }
  );
    // ==========================================================================
  // Vibe Check & Reactions — Phase 4
  // ==========================================================================

  /**
   * A user sends an emoji reaction.
   */
  socket.on(
    'send_reaction',
    async (payload: {
      code: string;
      userId: string;
      username: string;
      songId: string;
      type: ReactionType;
    }) => {
      try {
        // Verify current song matches
        const playback = await getPlaybackSync(payload.code);
        if (!playback || playback.songId !== payload.songId) {
          return; // Song changed, ignore stale reaction
        }

        const reaction: Reaction = {
          id: `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
          type: payload.type,
          userId: payload.userId,
          username: payload.username,
          songId: payload.songId,
          timestamp: Date.now(),
        };

        // Store in Redis
        await addReaction(payload.code, reaction);
                // Track in session
        await trackSessionEvent(payload.code, {
          type: 'reaction',
          userId: payload.userId,
          username: payload.username,
          timestamp: Date.now(),
          metadata: { reactionType: payload.type },
        });

        // Broadcast the reaction to EVERYONE (including sender)
        io.to(payload.code).emit('reaction_received', reaction);

        // Broadcast updated vibe state
        const vibe = await getVibeState(payload.code, payload.songId);
        io.to(payload.code).emit('vibe_updated', {
          songId: payload.songId,
          vibe,
        });

        console.log(
          `💫 Reaction in ${payload.code}: ${payload.username} → ${payload.type}`
        );
      } catch (err) {
        console.error('❌ send_reaction error:', err);
      }
    }
  );

  /**
   * Request current vibe state for a song.
   */
  socket.on(
    'vibe_request',
    async (payload: { code: string; songId: string }) => {
      try {
        const vibe = await getVibeState(payload.code, payload.songId);
        const reactions = await getRecentReactions(payload.code, payload.songId, 10);

        socket.emit('vibe_state', {
          songId: payload.songId,
          vibe,
          recentReactions: reactions,
        });
      } catch (err) {
        console.error('❌ vibe_request error:', err);
      }
    }
  );

    // ==========================================================================
  // Live Wrapped — Phase 5
  // ==========================================================================

  /**
   * End the current session and generate Wrapped.
   */
    socket.on(
    'end_session',
    async (payload: { code: string; userId: string }) => {
      console.log('📥 end_session:', payload);

      try {
        const djState = await getDjState(payload.code);

        // ---- DJ ONLY can end the session ----
        if (!djState || djState.currentDjId !== payload.userId) {
          socket.emit('room_error', {
            message: 'Only the current DJ can end the session',
          });
          return;
        }

        const wrapped = await generateWrapped(payload.code);
        if (!wrapped) {
          socket.emit('room_error', { message: 'Failed to generate Wrapped' });
          return;
        }

        // 1. Send Wrapped ONLY to the DJ who ended the session
        socket.emit('session_ended', wrapped);

        // 2. Tell everyone ELSE that the DJ ended the session
        socket.to(payload.code).emit('session_ending_notice', {
          endedByUsername: djState.currentDjUsername,
        });

        console.log(`🎬 Session ended by DJ ${djState.currentDjUsername} in ${payload.code}`);
      } catch (err) {
        console.error('❌ end_session error:', err);
      }
    }
  );

  /**
   * Request the current session stats (without ending).
   */
  socket.on('session_stats_request', async (payload: { code: string }) => {
    try {
      const wrapped = await generateWrapped(payload.code);
      socket.emit('session_stats', wrapped);
    } catch (err) {
      console.error('❌ session_stats_request error:', err);
    }
  });

    socket.on('search_live', async (payload: { query: string }) => {
    try {
      const results = await searchLive(payload.query);
      socket.emit('search_results', results);
    } catch (err) {
      console.error('❌ search_live error:', err);
      socket.emit('search_results', { rooms: [], users: [] });
    }
  });

  socket.on('explore_request', async () => {
    try {
      const data = await getExploreData();
      socket.emit('explore_data', data);
    } catch (err) {
      console.error('❌ explore_request error:', err);
      socket.emit('explore_data', { liveRooms: [], totalActiveListeners: 0 });
    }
  });
}