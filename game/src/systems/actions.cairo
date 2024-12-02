// Interface
#[starknet::interface]
pub trait IActions<TContractState> {

    ////////////////////
    // Read functions //
    ////////////////////
    
    fn game_id(self: @TContractState) -> u128;

    /////////////////////
    // Write functions //
    /////////////////////

    // Function to save the combat result
    // # Arguments
    // * ally_ships: The ally ships
    // * health_ships: The health ships
    // * result: The result of the combat
    fn combat(
        ref self: TContractState,
        ally_ships: Array<u128>,
        health_ships: Array<u32>,
        result: bool
    );

    // Function save the new position of the player on map
    // # Arguments
    // * x_position: The x position
    // * y_position: The y position
    fn move(ref self: TContractState, x_position: u32, y_position: u32);
}
// Contract
#[dojo::contract]
mod actions {
    // Starknet imports
    use starknet::{get_caller_address, get_block_timestamp, ContractAddress};
    // Dojo imports
    use dojo::{model::ModelStorage, world::WorldStorage, event::EventStorage};
    // Internal imports
    use genshin_tcg_v1::{
        constants::{DEFAULT_NS, GAME_ID},
        models::{
            combat::{Combat, CombatResult},
            movement::Movement,
            game::Game,
            ship::Ship,
            treasure_trip::TreasureTrip,
            position::Position
        },
        events::{CombatFinishedEvent, MovedEvent}
    };
    use super::IActions;
    
    #[abi(embed_v0)]
    impl IActionsImpl of IActions<ContractState> {

        ////////////////////
        // Read functions //
        ////////////////////
        
        fn game_id(self: @ContractState) -> u128 {
            GAME_ID
        }

        /////////////////////
        // Write functions //
        /////////////////////

        // See IActions - combat
        fn combat(
            ref self: ContractState,
            ally_ships: Array<u128>,
            health_ships: Array<u32>,
            result: bool
        ) {
            // Params validation
            assert(ally_ships.len() == health_ships.len(), 'error: invalid ships length');

            // Get World
            let mut world: WorldStorage = self.world(DEFAULT_NS());

            let caller = get_caller_address();
            let ally_ships_data = @ally_ships;
            let ally_ships_num = ally_ships.len();
            let ally_ships_clone = ally_ships.clone();

            // Increase total combat
            let mut game: Game = world.read_model(GAME_ID);
            game.total_combat += 1;

            // Decide result
            let mut game_result = CombatResult::Win;
            if (result == false) {
                game_result = CombatResult::Lose;
            }

            // Save ship health
            let mut i: u32 = 0;
            loop {
                if (i >= ally_ships_num) {
                    break;
                }

                // Get ship id
                let ship_id: u128 = *ally_ships_data.at(i);
                
                // Save ship
                world.write_model(
                    @Ship {
                        player_address: caller,
                        ship_id,
                        health: *health_ships.at(i)
                    }
                );

                i = i + 1;
            };

            // Save combat
            world.write_model(
                @Combat {
                    combat_id: game.total_combat,
                    ally_ships,
                    result: game_result
                }
            );

            // Save game
            world.write_model(
                @Game {
                    game_id: GAME_ID,
                    total_combat: game.total_combat,
                    total_move: game.total_move
                }
            );

            // Emit event
            world.emit_event(
                @CombatFinishedEvent {
                    combat_id: game.total_combat,
                    ally_ships: ally_ships_clone,
                    result: game_result
                }
            );
        }

        // See IActions - move
        fn move(
            ref self: ContractState,
            x_position: u32,
            y_position: u32
        ) {
            // Params validation
            assert(x_position >= 0 && y_position >= 0, 'error: invalid position');

            // Get World
            let mut world: WorldStorage = self.world(DEFAULT_NS());
            
            let player_address = get_caller_address();
            let timestamp = get_block_timestamp();

            // Get treasure trip by player address
            let mut treasure_trip: TreasureTrip = world.read_model(player_address);

            // Get ship old position
            let old_position = treasure_trip.position;

            // Update ship position
            treasure_trip.position = Position { x: x_position, y: y_position };

            // Increase total move
            let mut game: Game = world.read_model(GAME_ID);
            game.total_move += 1;

            // Save treasure trip
            world.write_model(
                @TreasureTrip {
                    player_address,
                    position: treasure_trip.position
                }
            );

            // Save move
            world.write_model(
                @Movement {
                    move_id: game.total_move,
                    timestamp,
                    player_address,
                    old_position,
                    new_position: treasure_trip.position
                }
            );

            // Save game
            world.write_model(
                @Game {
                    game_id: GAME_ID,
                    total_move: game.total_move,
                    total_combat: game.total_combat
                }
            );

            // Emit event
            world.emit_event(
                @MovedEvent {
                    move_id: game.total_move,
                    player_address,
                    timestamp,
                    old_position,
                    new_position: treasure_trip.position
                }
            );
        }
    }
}
