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
}