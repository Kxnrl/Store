#if defined _TransmitManager_included
  #endinput
#endif
#define _TransmitManager_included

#define TRANSMIT_MAX_CHANNEL 5
#define TRANSMIT_ALL_CHANNEL -1

/**
 * Adds entity hooks for the given entity to the Transmit Manager.
 *
 * @param entity The entity to add hooks for.
 * @param target The default state of the hooks.
 * @noreturn
 */
native void TransmitManager_AddEntityHooks(int entity, bool defaultState = true);


/**
 * Sets the owner of an entity.
 *
 * @param entity The entity to set the owner for.
 * @param target The target player to set as the owner.
 * @return True if the owner was set successfully, false otherwise.
 */
native bool TransmitManager_SetEntityOwner(int entity, int target);


/**
 * Sets the entity state for a specific client on a specific channel.
 *
 * @param entity The entity index to set the state for.
 * @param client The client index to set the state for.
 * @param can Whether the client can see the entity or not.
 * @param channel The channel to set the state for. Defaults to 0. Must be between -1 and TRANSMIT_MAX_CHANNEL. If set to -1, the state will be set for all channels.
 * @return True if the state was successfully set, false otherwise.
 */
native bool TransmitManager_SetEntityState(int entity, int client, bool can, int channel = 0);


/**
 * Retrieves the state of an entity for a specific client and channel.
 *
 * @param entity The entity index to retrieve the state of.
 * @param client The client index to retrieve the state for.
 * @param channel The channel to retrieve the state for. Defaults to 0. If set to -1, the state will be retrieved for default state.
 *
 * @return True if the entity should be transmit to client, false otherwise.
 */
native bool TransmitManager_GetEntityState(int entity, int client, int channel = 0);


/**
 * Sets the block state of an entity in the Transmit Manager.
 *
 * This function sets the block state of an entity in the Transmit Manager. The block state determines whether or not the entity is transmitted to clients.
 * @note The entity's owner bypasses the block state.
 *
 * @param entity The entity to set the block state for.
 * @param can The block state to set for the entity. True if the entity should be blocked, false otherwise.
 * @return True if the block state was successfully set, false otherwise.
 */
native bool TransmitManager_SetEntityBlock(int entity, bool can);


/**
 * Returns whether or not the given entity is blocked from transmitting to clients.
 *
 * @param entity The entity to check.
 * @return True if the entity is blocked from transmitting, false otherwise.
 */
native bool TransmitManager_GetEntityBlock(int entity);


/**
 * Checks if an entity is hooked by the Transmit Manager.
 *
 * @param entity The entity to check.
 * @return True if the entity is hooked, false otherwise.
 */
native bool TransmitManager_IsEntityHooked(int entity);


/**
 * _________________Do not edit below this line!_______________________
 */
public Extension __ext_transmit =
{
    name = "TransmitManager",
    file = "TransmitManager.ext",
#if defined AUTOLOAD_EXTENSIONS
    autoload = 1,
#else
    autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_transmit_SetNTVOptional()
{
    MarkNativeAsOptional("TransmitManager_AddEntityHooks");
    MarkNativeAsOptional("TransmitManager_SetEntityOwner");
    MarkNativeAsOptional("TransmitManager_SetEntityState");
    MarkNativeAsOptional("TransmitManager_GetEntityState");
    MarkNativeAsOptional("TransmitManager_SetEntityBlock");
    MarkNativeAsOptional("TransmitManager_GetEntityBlock");
    MarkNativeAsOptional("TransmitManager_IsEntityHooked");
}
#endif