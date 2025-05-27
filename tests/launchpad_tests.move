#[test_only]
module suilaunch::launchpad_tests {
    use sui::test_scenario::{Self, Scenario, next_tx, ctx};
    use sui::coin::{Self, Coin, mint_for_testing};
    use sui::clock::{Self, Clock};
    use sui::sui::SUI;
    use sui::transfer::public_transfer;
    use std::string;
    use suilaunch::launchpad::{
        Self, 
        Launchpad, 
        LaunchpadConfig, 
        StakingPool, 
        Allocation,
        KYCRecord,
        SUIX
    };

    // Test addresses
    const ADMIN: address = @0xA;
    const USER1: address = @0xB;
    // const USER2: address = @0xC; // Removed unused constant
    // const USER3: address = @0xD; // Removed unused constant
    const TEAM_WALLET: address = @0xE;
    const TOKEN_ADDRESS: address = @0xF;

    // Test constants
    const INITIAL_SUI: u64 = 10_000_000_000; // 10 SUI
    const INITIAL_SUIX: u64 = 1_000_000_000_000; // 1000 SUIX
    const TEST_TIME_START: u64 = 1000000;
    const TEST_TIME_END: u64 = 2000000;

    // ============ Helper Functions ============

    fun setup_test(): (Scenario, Clock) {
        let mut scenario = test_scenario::begin(ADMIN);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        clock::set_for_testing(&mut clock, TEST_TIME_START - 1000);

        // Initialize the module by calling the test_init function
        next_tx(&mut scenario, ADMIN);
        launchpad::test_init(ctx(&mut scenario));

        (scenario, clock)
    }

    // Helper function to initialize the module for testing
    // fun init_for_testing(ctx: &mut TxContext) { // Removed redundant function
    //     let config = LaunchpadConfig {
    //         id: sui::object::new(ctx),
    //         admin: sui::tx_context::sender(ctx),
    //         protocol_fee: 250, // 2.5%
    //         min_vetting_score: 70,
    //         max_projects_per_week: 5,
    //         treasury: sui::tx_context::sender(ctx),
    //     };
    //     sui::transfer::share_object(config);

    //     // Create initial staking pool
    //     let staking_pool = StakingPool {
    //         id: sui::object::new(ctx),
    //         admin: sui::tx_context::sender(ctx),
    //         total_staked: sui::balance::zero(),
    //         user_stakes: sui::table::new(ctx),
    //         reward_rate: 100, // 1% per epoch
    //         last_update: 0,
    //         is_active: true,
    //     };
    //     sui::transfer::share_object(staking_pool);
    // }

    fun create_test_coins(scenario: &mut Scenario, user: address, sui_amount: u64, suix_amount: u64) {
        next_tx(scenario, user);
        {
            let sui_coin = mint_for_testing<SUI>(sui_amount, ctx(scenario));
            let suix_coin = mint_for_testing<SUIX>(suix_amount, ctx(scenario));
            public_transfer(sui_coin, user);
            public_transfer(suix_coin, user);
        };
    }

    fun create_test_launchpad(scenario: &mut Scenario) {
        next_tx(scenario, ADMIN);
        {
            let config = test_scenario::take_shared<LaunchpadConfig>(scenario);
            
            launchpad::create_launchpad(
                &config,
                b"TestToken",
                b"TT",
                b"A test token for IDO",
                b"https://testtoken.com",
                TOKEN_ADDRESS,
                TEAM_WALLET,
                75, // vetting score
                1000000000000, // 1M tokens
                1000000, // 1 SUI per 1000 tokens
                100000000, // min 0.1 SUI
                1000000000, // max 1 SUI
                TEST_TIME_START,
                TEST_TIME_END,
                true, // KYC required
                ctx(scenario)
            );
            
            test_scenario::return_shared(config);
        };
    }

    fun create_kyc_record(scenario: &mut Scenario, clock: &Clock, user: address, tier: u8) {
        next_tx(scenario, ADMIN);
        {
            launchpad::verify_kyc(user, tier, clock, ctx(scenario));
        };
    }

    // ============ Initialization Tests ============

    #[test]
    fun test_init_success() {
        let (mut scenario, clock) = setup_test();
        
        next_tx(&mut scenario, ADMIN);
        {
            // Check that LaunchpadConfig was created and shared
            assert!(test_scenario::has_most_recent_shared<LaunchpadConfig>(), 0);
            
            // Check that StakingPool was created and shared
            assert!(test_scenario::has_most_recent_shared<StakingPool>(), 1);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    // ============ Launchpad Creation Tests ============

    #[test]
    fun test_create_launchpad_success() {
        let (mut scenario, clock) = setup_test();
        create_test_launchpad(&mut scenario);
        
        next_tx(&mut scenario, ADMIN);
        {
            // Verify launchpad was created
            assert!(test_scenario::has_most_recent_shared<Launchpad>(), 0);
            
            let launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let (name, total_allocation, raised, contributors, active) = 
                launchpad::get_launchpad_info(&launchpad);
            
            assert!(name == string::utf8(b"TestToken"), 1);
            assert!(total_allocation == 1000000000000, 2);
            assert!(raised == 0, 3);
            assert!(contributors == 0, 4);
            assert!(active == true, 5);
            
            test_scenario::return_shared(launchpad);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::E_NOT_ADMIN)]
    fun test_create_launchpad_not_admin() {
        let (mut scenario, clock) = setup_test();
        
        next_tx(&mut scenario, USER1);
        {
            let config = test_scenario::take_shared<LaunchpadConfig>(&scenario);
            
            launchpad::create_launchpad(
                &config,
                b"TestToken",
                b"TT",
                b"A test token for IDO",
                b"https://testtoken.com",
                TOKEN_ADDRESS,
                TEAM_WALLET,
                75,
                1000000000000,
                1000000,
                100000000,
                1000000000,
                TEST_TIME_START,
                TEST_TIME_END,
                true,
                ctx(&mut scenario)
            );
            
            test_scenario::return_shared(config);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::E_VETTING_SCORE_TOO_LOW)]
    fun test_create_launchpad_low_vetting_score() {
        let (mut scenario, clock) = setup_test();
        
        next_tx(&mut scenario, ADMIN);
        {
            let config = test_scenario::take_shared<LaunchpadConfig>(&scenario);
            
            launchpad::create_launchpad(
                &config,
                b"TestToken",
                b"TT",
                b"A test token for IDO",
                b"https://testtoken.com",
                TOKEN_ADDRESS,
                TEAM_WALLET,
                65, // Below minimum vetting score
                1000000000000,
                1000000,
                100000000,
                1000000000,
                TEST_TIME_START,
                TEST_TIME_END,
                true,
                ctx(&mut scenario)
            );
            
            test_scenario::return_shared(config);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    // ============ Staking Tests ============

    #[test]
    fun test_stake_tokens_success() {
        let (mut scenario, clock) = setup_test();
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        
        next_tx(&mut scenario, USER1);
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            let mut suix_coin = test_scenario::take_from_sender<Coin<SUIX>>(&scenario);
            
            // Stake 500 SUIX (should be tier 2)
            let stake_amount = 500_000_000; // Adjusted to match TIER_2_THRESHOLD
            let staking_coin = coin::split(&mut suix_coin, stake_amount, ctx(&mut scenario));
            
            launchpad::stake_tokens(&mut pool, staking_coin, &clock, ctx(&mut scenario));
            
            // Check user stake info
            let (amount, tier, multiplier) = launchpad::get_user_stake(&pool, USER1);
            assert!(amount == stake_amount, 0);
            assert!(tier == 2, 1); // 500 SUIX should be tier 2
            assert!(multiplier == 3, 2); // Tier 2 multiplier is 3x
            
            test_scenario::return_to_sender(&scenario, suix_coin);
            test_scenario::return_shared(pool);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    // ============ KYC Tests ============

    #[test]
    fun test_verify_kyc_success() {
        let (mut scenario, clock) = setup_test();
        
        create_kyc_record(&mut scenario, &clock, USER1, 2);
        
        next_tx(&mut scenario, USER1);
        {
            let kyc_record = test_scenario::take_from_sender<KYCRecord>(&scenario);
            // KYC record should be created and transferred to user
            test_scenario::return_to_sender(&scenario, kyc_record);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    // ============ IDO Contribution Tests ============

    #[test]
    fun test_contribute_success() {
        let (mut scenario, mut clock) = setup_test();
        create_test_launchpad(&mut scenario);
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        
        // Create KYC record
        create_kyc_record(&mut scenario, &clock, USER1, 2);
        
        // Stake some tokens for tier bonus
        next_tx(&mut scenario, USER1);
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            let mut suix_coin = test_scenario::take_from_sender<Coin<SUIX>>(&scenario);
            
            let stake_amount = 500_000_000_000; // Tier 2
            let staking_coin = coin::split(&mut suix_coin, stake_amount, ctx(&mut scenario));
            
            launchpad::stake_tokens(&mut pool, staking_coin, &clock, ctx(&mut scenario));
            
            test_scenario::return_to_sender(&scenario, suix_coin);
            test_scenario::return_shared(pool);
        };

        // Set time to IDO period
        clock::set_for_testing(&mut clock, TEST_TIME_START + 1000);

        // Contribute to IDO
        next_tx(&mut scenario, USER1);
        {
            let mut launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let staking_pool = test_scenario::take_shared<StakingPool>(&scenario);
            let kyc_record = test_scenario::take_from_sender<KYCRecord>(&scenario);
            let mut sui_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            
            let contribution_coin = coin::split(&mut sui_coin, 500_000_000, ctx(&mut scenario));
            
            launchpad::contribute(
                &mut launchpad,
                &staking_pool,
                &kyc_record,
                &clock,
                contribution_coin,
                ctx(&mut scenario)
            );
            
            test_scenario::return_to_sender(&scenario, sui_coin);
            test_scenario::return_to_sender(&scenario, kyc_record);
            test_scenario::return_shared(staking_pool);
            test_scenario::return_shared(launchpad);
        };

        // Check allocation was created
        next_tx(&mut scenario, USER1);
        {
            let allocation = test_scenario::take_from_sender<Allocation>(&scenario);
            test_scenario::return_to_sender(&scenario, allocation);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    // ============ View Function Tests ============

    #[test]
    fun test_get_launchpad_info() {
        let (mut scenario, clock) = setup_test();
        create_test_launchpad(&mut scenario);
        
        next_tx(&mut scenario, USER1);
        {
            let launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let (name, total_allocation, raised, contributors, active) = 
                launchpad::get_launchpad_info(&launchpad);
            
            assert!(name == string::utf8(b"TestToken"), 0);
            assert!(total_allocation == 1000000000000, 1);
            assert!(raised == 0, 2);
            assert!(contributors == 0, 3);
            assert!(active == true, 4);
            
            test_scenario::return_shared(launchpad);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_user_stake_no_stake() {
        let (mut scenario, clock) = setup_test();
        
        next_tx(&mut scenario, USER1);
        {
            let pool = test_scenario::take_shared<StakingPool>(&scenario);
            let (amount, tier, multiplier) = launchpad::get_user_stake(&pool, USER1);
            
            assert!(amount == 0, 0);
            assert!(tier == 0, 1);
            assert!(multiplier == 1, 2);
            
            test_scenario::return_shared(pool);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_vetting_score() {
        let (mut scenario, clock) = setup_test();
        create_test_launchpad(&mut scenario);
        
        next_tx(&mut scenario, USER1);
        {
            let launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let score = launchpad::get_vetting_score(&launchpad);
            
            assert!(score == 75, 0);
            
            test_scenario::return_shared(launchpad);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_is_ido_active() {
        let (mut scenario, mut clock) = setup_test();
        create_test_launchpad(&mut scenario);
        
        // Test before start time
        next_tx(&mut scenario, USER1);
        {
            let launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let active = launchpad::is_ido_active(&launchpad, &clock);
            
            assert!(active == false, 0);
            
            test_scenario::return_shared(launchpad);
        };

        // Test during IDO period
        clock::set_for_testing(&mut clock, TEST_TIME_START + 1000);
        
        next_tx(&mut scenario, USER1);
        {
            let launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let active = launchpad::is_ido_active(&launchpad, &clock);
            
            assert!(active == true, 1);
            
            test_scenario::return_shared(launchpad);
        };

        // Test after end time
        clock::set_for_testing(&mut clock, TEST_TIME_END + 1000);
        
        next_tx(&mut scenario, USER1);
        {
            let launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let active = launchpad::is_ido_active(&launchpad, &clock);
            
            assert!(active == false, 2);
            
            test_scenario::return_shared(launchpad);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    // ============ Error Case Tests ============

    #[test]
    #[expected_failure(abort_code = launchpad::E_IDO_NOT_STARTED)]
    fun test_contribute_before_start_time() {
        let (mut scenario, clock) = setup_test();
        create_test_launchpad(&mut scenario);
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        create_kyc_record(&mut scenario, &clock, USER1, 2);

        // Try to contribute before start time
        next_tx(&mut scenario, USER1);
        {
            let mut launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let staking_pool = test_scenario::take_shared<StakingPool>(&scenario);
            let kyc_record = test_scenario::take_from_sender<KYCRecord>(&scenario);
            let mut sui_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            
            let contribution_coin = coin::split(&mut sui_coin, 500_000_000, ctx(&mut scenario));
            
            launchpad::contribute(
                &mut launchpad,
                &staking_pool,
                &kyc_record,
                &clock,
                contribution_coin,
                ctx(&mut scenario)
            );
            
            test_scenario::return_to_sender(&scenario, sui_coin);
            test_scenario::return_to_sender(&scenario, kyc_record);
            test_scenario::return_shared(staking_pool);
            test_scenario::return_shared(launchpad);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::E_CONTRIBUTION_LIMITS)]
    fun test_contribute_below_minimum() {
        let (mut scenario, mut clock) = setup_test();
        create_test_launchpad(&mut scenario);
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        create_kyc_record(&mut scenario, &clock, USER1, 2);

        // Set time to IDO period
        clock::set_for_testing(&mut clock, TEST_TIME_START + 1000);

        next_tx(&mut scenario, USER1);
        {
            let mut launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let staking_pool = test_scenario::take_shared<StakingPool>(&scenario);
            let kyc_record = test_scenario::take_from_sender<KYCRecord>(&scenario);
            let mut sui_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            
            // Contribute below minimum (min is 0.1 SUI)
            let contribution_coin = coin::split(&mut sui_coin, 50_000_000, ctx(&mut scenario));
            
            launchpad::contribute(
                &mut launchpad,
                &staking_pool,
                &kyc_record,
                &clock,
                contribution_coin,
                ctx(&mut scenario)
            );
            
            test_scenario::return_to_sender(&scenario, sui_coin);
            test_scenario::return_to_sender(&scenario, kyc_record);
            test_scenario::return_shared(staking_pool);
            test_scenario::return_shared(launchpad);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    // ============ Edge Case Tests ============

    #[test]
    #[expected_failure(abort_code = launchpad::E_INVALID_AMOUNT)]
    fun test_create_launchpad_start_time_equals_end_time() {
        let (mut scenario, clock) = setup_test();
        next_tx(&mut scenario, ADMIN);
        {
            let config = test_scenario::take_shared<LaunchpadConfig>(&scenario);
            launchpad::create_launchpad(
                &config,
                b"TestTokenEdge",
                b"TTE",
                b"A test token for edge case",
                b"https://testtokenedge.com",
                TOKEN_ADDRESS,
                TEAM_WALLET,
                75,
                1000000000000,
                1000000,
                100000000,
                1000000000,
                TEST_TIME_START, // start_time
                TEST_TIME_START, // end_time is same as start_time
                true,
                ctx(&mut scenario)
            );
            test_scenario::return_shared(config);
        };
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::E_INVALID_AMOUNT)]
    fun test_create_launchpad_min_greater_than_max_contribution() {
        let (mut scenario, clock) = setup_test();
        next_tx(&mut scenario, ADMIN);
        {
            let config = test_scenario::take_shared<LaunchpadConfig>(&scenario);
            launchpad::create_launchpad(
                &config,
                b"TestTokenEdge",
                b"TTE",
                b"A test token for edge case",
                b"https://testtokenedge.com",
                TOKEN_ADDRESS,
                TEAM_WALLET,
                75,
                1000000000000,
                1000000,
                1000000000, // min_contribution
                100000000,  // max_contribution is less than min
                TEST_TIME_START,
                TEST_TIME_END,
                true,
                ctx(&mut scenario)
            );
            test_scenario::return_shared(config);
        };
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    // Assuming staking 0 should be disallowed; if not, this needs E_INVALID_AMOUNT and contract change.
    // For now, let's assume it might fail due to coin::split with 0 or table handling.
    // If it passes, it means staking 0 tokens is allowed and does nothing or creates a 0-tier stake.
    fun test_stake_zero_tokens() {
        let (mut scenario, clock) = setup_test();
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        next_tx(&mut scenario, USER1);
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            let mut suix_coin = test_scenario::take_from_sender<Coin<SUIX>>(&scenario);
            
            let stake_amount = 0;
            let staking_coin = coin::split(&mut suix_coin, stake_amount, ctx(&mut scenario));
            
            launchpad::stake_tokens(&mut pool, staking_coin, &clock, ctx(&mut scenario));
            
            let (amount, tier, multiplier) = launchpad::get_user_stake(&pool, USER1);
            assert!(amount == 0, 0);
            assert!(tier == 0, 1);
            assert!(multiplier == 1, 2); // Tier 0, 1x multiplier for 0 stake
            
            test_scenario::return_to_sender(&scenario, suix_coin); // Original coin + remaining from split
            test_scenario::return_shared(pool);
        };
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_unstake_zero_tokens() {
        let (mut scenario, clock) = setup_test();
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        next_tx(&mut scenario, USER1);
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            // Stake some tokens first
            let mut suix_coin = test_scenario::take_from_sender<Coin<SUIX>>(&scenario);
            let initial_stake = 100_000_000;
            let staking_coin = coin::split(&mut suix_coin, initial_stake, ctx(&mut scenario));
            launchpad::stake_tokens(&mut pool, staking_coin, &clock, ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, suix_coin); // Return the remaining SUIX coin
            test_scenario::return_shared(pool); // Return pool before taking it again
        };

        next_tx(&mut scenario, USER1); // New transaction for unstaking
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            launchpad::unstake_tokens(&mut pool, 0, ctx(&mut scenario)); // Unstake 0
            
            let (amount, _, _) = launchpad::get_user_stake(&pool, USER1);
            assert!(amount == 100_000_000, 0); // Amount should be unchanged
            
            test_scenario::return_shared(pool);
        };
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_unstake_full_amount() {
        let (mut scenario, clock) = setup_test();
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        let initial_stake_amount = 100_000_000; // Tier 1

        next_tx(&mut scenario, USER1);
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            let mut suix_coin = test_scenario::take_from_sender<Coin<SUIX>>(&scenario);
            let staking_coin = coin::split(&mut suix_coin, initial_stake_amount, ctx(&mut scenario));
            launchpad::stake_tokens(&mut pool, staking_coin, &clock, ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, suix_coin);
            test_scenario::return_shared(pool);
        };

        next_tx(&mut scenario, USER1);
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            launchpad::unstake_tokens(&mut pool, initial_stake_amount, ctx(&mut scenario));
            let (amount, tier, multiplier) = launchpad::get_user_stake(&pool, USER1);
            assert!(amount == 0, 0);
            assert!(tier == 0, 1);
            assert!(multiplier == 1, 2);
            test_scenario::return_shared(pool);
        };
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_contribute_exact_min() {
        let (mut scenario, mut clock) = setup_test();
        create_test_launchpad(&mut scenario);
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        create_kyc_record(&mut scenario, &clock, USER1, 1);
        clock::set_for_testing(&mut clock, TEST_TIME_START + 100);

        next_tx(&mut scenario, USER1);
        {
            let mut launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let staking_pool = test_scenario::take_shared<StakingPool>(&scenario);
            let kyc_record = test_scenario::take_from_sender<KYCRecord>(&scenario);
            let mut sui_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            
            let min_contribution = 100_000_000; // From create_test_launchpad
            let contribution_coin = coin::split(&mut sui_coin, min_contribution, ctx(&mut scenario));
            
            launchpad::contribute(
                &mut launchpad,
                &staking_pool,
                &kyc_record,
                &clock,
                contribution_coin,
                ctx(&mut scenario)
            );
            
            // Check raised amount
            let (_, _, raised, _, _) = launchpad::get_launchpad_info(&launchpad);
            assert!(raised == min_contribution, 0);

            test_scenario::return_to_sender(&scenario, sui_coin);
            test_scenario::return_to_sender(&scenario, kyc_record);
            test_scenario::return_shared(staking_pool);
            test_scenario::return_shared(launchpad);
        };
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_contribute_exact_max() {
        let (mut scenario, mut clock) = setup_test();
        create_test_launchpad(&mut scenario);
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        create_kyc_record(&mut scenario, &clock, USER1, 1);
        clock::set_for_testing(&mut clock, TEST_TIME_START + 100);

        next_tx(&mut scenario, USER1);
        {
            let mut launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let staking_pool = test_scenario::take_shared<StakingPool>(&scenario);
            let kyc_record = test_scenario::take_from_sender<KYCRecord>(&scenario);
            let mut sui_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            
            let max_contribution = 1_000_000_000; // From create_test_launchpad
            let contribution_coin = coin::split(&mut sui_coin, max_contribution, ctx(&mut scenario));
            
            launchpad::contribute(
                &mut launchpad,
                &staking_pool,
                &kyc_record,
                &clock,
                contribution_coin,
                ctx(&mut scenario)
            );
            
            let (_, _, raised, _, _) = launchpad::get_launchpad_info(&launchpad);
            assert!(raised == max_contribution, 0);

            test_scenario::return_to_sender(&scenario, sui_coin);
            test_scenario::return_to_sender(&scenario, kyc_record);
            test_scenario::return_shared(staking_pool);
            test_scenario::return_shared(launchpad);
        };
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::E_KYC_NOT_COMPLETED)]
    fun test_contribute_kyc_required_no_kyc_record() {
        let (mut scenario, mut clock) = setup_test();
        create_test_launchpad(&mut scenario); // kyc_required is true by default here
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        // DO NOT create KYC record for USER1
        clock::set_for_testing(&mut clock, TEST_TIME_START + 100);

        // Create a KYC record for a *different* user (ADMIN) to simulate USER1 not having a valid one for the transaction.
        create_kyc_record(&mut scenario, &clock, ADMIN, 0); // This is within next_tx(ADMIN)

        // Admin takes their KYC record
        let kyc_record_for_admin: KYCRecord;
        next_tx(&mut scenario, ADMIN);
        {
            kyc_record_for_admin = test_scenario::take_from_sender<KYCRecord>(&scenario);
        };

        // USER1 attempts to contribute using ADMIN's KYC record
        next_tx(&mut scenario, USER1);
        {
            let mut launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let staking_pool = test_scenario::take_shared<StakingPool>(&scenario);
            let mut sui_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            let contribution_coin = coin::split(&mut sui_coin, 100_000_000, ctx(&mut scenario));

            launchpad::contribute(
                &mut launchpad,
                &staking_pool,
                &kyc_record_for_admin, // Pass ADMIN's KYC record while USER1 is sender
                &clock,
                contribution_coin,
                ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&scenario, sui_coin);
            test_scenario::return_shared(staking_pool);
            test_scenario::return_shared(launchpad);
            // kyc_record_for_admin will be returned in the ADMIN context below
        };
        
        // Admin gets their KYC record back
        next_tx(&mut scenario, ADMIN);
        {
            test_scenario::return_to_sender(&scenario, kyc_record_for_admin);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = launchpad::E_IDO_NOT_STARTED)] // Current error for claiming too early
    fun test_claim_tokens_during_ido() {
        let (mut scenario, mut clock) = setup_test();
        create_test_launchpad(&mut scenario);
        create_test_coins(&mut scenario, USER1, INITIAL_SUI, INITIAL_SUIX);
        create_kyc_record(&mut scenario, &clock, USER1, 1);

        // Contribute to create an allocation
        clock::set_for_testing(&mut clock, TEST_TIME_START + 100);
        next_tx(&mut scenario, USER1);
        {
            let mut launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let staking_pool = test_scenario::take_shared<StakingPool>(&scenario);
            let kyc_record = test_scenario::take_from_sender<KYCRecord>(&scenario);
            let mut sui_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            let contribution_coin = coin::split(&mut sui_coin, 100_000_000, ctx(&mut scenario));
            launchpad::contribute(&mut launchpad, &staking_pool, &kyc_record, &clock, contribution_coin, ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, sui_coin);
            test_scenario::return_to_sender(&scenario, kyc_record);
            test_scenario::return_shared(staking_pool);
            test_scenario::return_shared(launchpad);
        };

        // Try to claim while IDO is still active (before TEST_TIME_END)
        // clock is still at TEST_TIME_START + 100
        next_tx(&mut scenario, USER1);
        {
            let launchpad = test_scenario::take_shared<Launchpad>(&scenario);
            let mut allocation = test_scenario::take_from_sender<Allocation>(&scenario);
            
            launchpad::claim_tokens(&launchpad, &mut allocation, &clock, ctx(&mut scenario));
            
            test_scenario::return_to_sender(&scenario, allocation);
            test_scenario::return_shared(launchpad);
        };
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}