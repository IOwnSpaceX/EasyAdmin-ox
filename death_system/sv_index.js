// ========================================================================================================================
//                                                        EVENTS
// ------------------------------------------------------------------------------------------------------------------------
//                            MAKES SURE YOU KNOW WHAT YOU'RE DOING BEFORE YOU CHANGE ANYTHING
// ========================================================================================================================

onNet('DeathScript:Admin:CheckAce', (Moderator, Command) => {
    if (IsPlayerAceAllowed(Moderator, `DeathScript.${Command.toLowerCase()}`)) {
        emitNet('DeathScript:Admin:CheckAce:Return', Moderator, Moderator, Command, true);
    } else {
        emitNet('DeathScript:Admin:CheckAce:Return', Moderator, Moderator, Command, false);
    }
});

onNet('DeathScript:Admin:ValidatePlayer', (Moderator, Player, Command) => {
    if (ValidatePlayer(Moderator, Player, Command)) {
        const Ped = GetPlayerPed(Player);
        if (GetEntityHealth(Ped) > 1) {
            if (parseInt(Player) === Moderator) {
                SendMessage(Moderator, Config.Commands[Command].Messages.ToStaff.YouAlive);
            } else {
                SendMessage(Moderator, Config.Commands[Command].Messages.ToStaff.Alive);
            }
        } else {
            if (Command === 'AdRev') {
                emitNet('DeathScript:Admin:Revive', Player, Moderator, false);
            } else {
                emitNet('DeathScript:Admin:Respawn', Player, Moderator, false);
            }
            if (parseInt(Player) === Moderator) {
                SendMessage(Moderator, Config.Commands[Command].Messages.ToStaff[Command === 'AdRev' ? 'Revived' : 'Respawned']);
            } else {
                SendMessage(Moderator, Config.Commands[Command].Messages.ToStaff[Command === 'AdRev' ? 'Revived' : 'Respawned']);
                SendMessage(Player, Config.Commands[Command].Messages.ToPlayer[Command === 'AdRev' ? 'Revived' : 'Respawned']);
            }
        }
    }
});

// ========================================================================================================================
//                                                        FUNCTIONS
// ------------------------------------------------------------------------------------------------------------------------
//                            MAKES SURE YOU KNOW WHAT YOU'RE DOING BEFORE YOU CHANGE ANYTHING
// ========================================================================================================================

/**
 * @name ValidatePlayer
 * @description Used to check whether the player is present in the server or not; and reply if not present or incorrect syntax was used
 * @returns {boolean} True/False
 * @example ValidatePlayer(StaffId, PlayerId, 'adrev')
 */
const ValidatePlayer = (Source, Player, Command) => {
    if (!isNaN(Player)) {
        if (GetPlayerEndpoint(Player)) {
            return true;
        } else {
            SendMessage(Source, Config.Commands[Command].Messages.ToStaff.NotFound);
        }
    } else if (Player.toLowerCase() === 'all') {
        return true;
    } else {
        SendMessage(Source, Config.Commands[Command].Messages.ToStaff.IdNumber);
    }
};

/**
 * @name SendMessage
 * @description A shortcut function to emit a 'chat:addMessage' event to send a message to a specific player or all
 * @returns Returnless
 * @example SendMessage(StaffId, ['(INFO)', 'Incorrect ID!'])
 */
const SendMessage = (Recipient, MessageArgs) => Recipient === 0 ? console.log(MessageArgs.join(' ') + '^0') : emitNet('chat:addMessage', Recipient, { args: MessageArgs, multiline: true });

// ========================================================================================================================
//                                                        EXPORTS
// ------------------------------------------------------------------------------------------------------------------------
//                            MAKES SURE YOU KNOW WHAT YOU'RE DOING BEFORE YOU CHANGE ANYTHING
// ========================================================================================================================

exports('Revive', (PlayerId) => {
    if (!isNaN(Player)) {
        const Ped = GetPlayerPed(PlayerId);
        if (GetEntityHealth(Ped) <= 1) {
            emitNet('DeathScript:Admin:Revive', PlayerId, 0, false);
        }
    } else if (PlayerId.toLowerCase() === 'all') {
        emitNet('DeathScript:Admin:Revive', -1, 0, true);
    }
});

exports('Respawn', (PlayerId) => {
    if (!isNaN(Player)) {
        const Ped = GetPlayerPed(PlayerId);
        if (GetEntityHealth(Ped) <= 1) {
            emitNet('DeathScript:Admin:Respawn', PlayerId, 0, false);
        }
    } else if (PlayerId.toLowerCase() === 'all') {
        emitNet('DeathScript:Admin:Respawn', -1, 0, true);
    }
});