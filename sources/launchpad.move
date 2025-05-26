/// SuiLaunch - A decentralized IDO launchpad on Sui blockchain
/// Provides secure, scalable token launches with investor protections
module suilaunch::launchpad {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::transfer::{public_transfer, share_object};
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::table::{Self, Table};
    use sui::sui::SUI;
    use std::string::{Self, String};

    // ============ Structs ============

    /// One-time witness for module initialization
    public struct LAUNCHPAD has drop {}

    /// Main launchpad object for managing IDOs
    public struct Launchpad has key, store {
        id: UID,
        admin: address,
        project: ProjectInfo,
        total_allocation: u64,
        raised_amount: Balance<SUI>,
        token_price: u64, // Price in SUI per token
        min_contribution: u64,
        max_contribution: u64,
        start_time: u64,
        end_time: u64,
        kyc_required: bool,
        is_active: bool,
        total_contributors: u64,
        refund_enabled: bool,
    }

    /// Project information stored on-chain
    public struct ProjectInfo has store, copy, drop {
        name: String,
        symbol: String,
        description: String,
        website: String,
        token_address: address,
        vetting_score: u8, // 0-100 score
        team_wallet: address,
    }

    /// Staking pool for $SUIX tokens
    public struct StakingPool has key, store {
        id: UID,
        admin: address,
        total_staked: Balance<SUIX>,
        user_stakes: Table<address, UserStake>,
        reward_rate: u64, // Rewards per block
        last_update: u64,
        is_active: bool,
    }

    /// Individual user stake information
    public struct UserStake has store, copy, drop {
        amount: u64,
        tier: u8,
        stake_time: u64,
        rewards_earned: u64,
        allocation_multiplier: u64, // Based on tier
    }

    /// User's IDO allocation
    public struct Allocation has key, store {
        id: UID,
        launchpad_id: ID,
        user: address,
        contributed_amount: u64,
        token_allocation: u64,
        claimed: bool,
        refunded: bool,
        contribution_time: u64,
    }

    /// KYC verification record
    public struct KYCRecord has key, store {
        id: UID,
        user: address,
        verified: bool,
        verification_time: u64,
        tier_level: u8,
    }

    /// Launchpad configuration and fee structure
    public struct LaunchpadConfig has key, store {
        id: UID,
        admin: address,
        protocol_fee: u64, // Basis points (e.g., 250 = 2.5%)
        min_vetting_score: u8,
        max_projects_per_week: u64,
        treasury: address,
    }

    /// Platform token for staking and governance
    public struct SUIX has drop {}

    // ============ Events ============

    public struct IDOCreated has copy, drop {
        launchpad_id: ID,
        project_name: String,
        total_allocation: u64,
        start_time: u64,
        end_time: u64,
    }

    public struct IDOContribution has copy, drop {
        launchpad_id: ID,
        user: address,
        amount: u64,
        token_allocation: u64,
        timestamp: u64,
    }

    public struct TokensClaimed has copy, drop {
        launchpad_id: ID,
        user: address,
        amount: u64,
        timestamp: u64,
    }

    public struct TokensStaked has copy, drop {
        user: address,
        amount: u64,
        tier: u8,
        timestamp: u64,
    }

    public struct RefundIssued has copy, drop {
        launchpad_id: ID,
        user: address,
        amount: u64,
        timestamp: u64,
    }

    public struct KYCVerified has copy, drop {
        user: address,
        tier_level: u8,
        timestamp: u64,
    }

    // ============ Error Constants ============
    
    const E_NOT_ADMIN: u64 = 1;
    const E_IDO_NOT_STARTED: u64 = 2;
    const E_IDO_ENDED: u64 = 3;
    const E_IDO_NOT_ACTIVE: u64 = 4;
    const E_KYC_NOT_COMPLETED: u64 = 5;
    const E_ALREADY_CLAIMED: u64 = 7;
    const E_NOT_AUTHORIZED: u64 = 8;
    const E_INVALID_AMOUNT: u64 = 9;
    const E_CONTRIBUTION_LIMITS: u64 = 10;
    const E_VETTING_SCORE_TOO_LOW: u64 = 11;
    const E_ALREADY_REFUNDED: u64 = 12;
    const E_REFUND_NOT_ENABLED: u64 = 13;
    const E_STAKING_NOT_ACTIVE: u64 = 14;
    const E_INSUFFICIENT_STAKE: u64 = 15;

    // ============ Constants ============
    
    const MIN_VETTING_SCORE: u8 = 70;
    const TIER_1_THRESHOLD: u64 = 100_000_000; // 100 SUIX
    const TIER_2_THRESHOLD: u64 = 500_000_000; // 500 SUIX
    const TIER_3_THRESHOLD: u64 = 1000_000_000; // 1000 SUIX

    // ============ Initialization Functions ============

    /// Initialize the launchpad platform
    fun init(_witness: LAUNCHPAD, ctx: &mut TxContext) {
        let config = LaunchpadConfig {
            id: sui::object::new(ctx),
            admin: sui::tx_context::sender(ctx),
            protocol_fee: 250, // 2.5%
            min_vetting_score: MIN_VETTING_SCORE,
            max_projects_per_week: 5,
            treasury: sui::tx_context::sender(ctx),
        };
        share_object(config);

        // Create initial staking pool
        let staking_pool = StakingPool {
            id: sui::object::new(ctx),
            admin: sui::tx_context::sender(ctx),
            total_staked: balance::zero(),
            user_stakes: table::new(ctx),
            reward_rate: 100, // 1% per epoch
            last_update: 0,
            is_active: true,
        };
        share_object(staking_pool);
    }

    /// Public initializer for testing purposes
    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(LAUNCHPAD {}, ctx);
    }

    // ============ Admin Functions ============

    /// Create a new IDO launchpad
    public entry fun create_launchpad(
        config: &LaunchpadConfig,
        name: vector<u8>,
        symbol: vector<u8>,
        description: vector<u8>,
        website: vector<u8>,
        token_address: address,
        team_wallet: address,
        vetting_score: u8,
        total_allocation: u64,
        token_price: u64,
        min_contribution: u64,
        max_contribution: u64,
        start_time: u64,
        end_time: u64,
        kyc_required: bool,
        ctx: &mut TxContext
    ) {
        assert!(sui::tx_context::sender(ctx) == config.admin, E_NOT_ADMIN);
        assert!(vetting_score >= config.min_vetting_score, E_VETTING_SCORE_TOO_LOW);
        assert!(start_time < end_time, E_INVALID_AMOUNT);
        assert!(min_contribution <= max_contribution, E_INVALID_AMOUNT);

        let project = ProjectInfo {
            name: string::utf8(name),
            symbol: string::utf8(symbol),
            description: string::utf8(description),
            website: string::utf8(website),
            token_address,
            vetting_score,
            team_wallet,
        };

        let launchpad = Launchpad {
            id: sui::object::new(ctx),
            admin: sui::tx_context::sender(ctx),
            project,
            total_allocation,
            raised_amount: balance::zero(),
            token_price,
            min_contribution,
            max_contribution,
            start_time,
            end_time,
            kyc_required,
            is_active: true,
            total_contributors: 0,
            refund_enabled: false,
        };

        let launchpad_id = sui::object::id(&launchpad);
        
        event::emit(IDOCreated {
            launchpad_id,
            project_name: project.name,
            total_allocation,
            start_time,
            end_time,
        });

        share_object(launchpad);
    }

    /// Enable refunds for a launchpad (admin only)
    public entry fun enable_refunds(
        launchpad: &mut Launchpad,
        ctx: &mut TxContext
    ) {
        assert!(sui::tx_context::sender(ctx) == launchpad.admin, E_NOT_ADMIN);
        launchpad.refund_enabled = true;
    }

    /// Verify KYC for a user
    public entry fun verify_kyc(
        user: address,
        tier_level: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let kyc_record = KYCRecord {
            id: sui::object::new(ctx),
            user,
            verified: true,
            verification_time: clock::timestamp_ms(clock),
            tier_level,
        };

        event::emit(KYCVerified {
            user,
            tier_level,
            timestamp: clock::timestamp_ms(clock),
        });

        public_transfer(kyc_record, user);
    }

    // ============ Staking Functions ============

    /// Stake SUIX tokens to earn allocation points
    public entry fun stake_tokens(
        pool: &mut StakingPool,
        tokens: Coin<SUIX>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(pool.is_active, E_STAKING_NOT_ACTIVE);
        
        let amount = coin::value(&tokens);
        let user = sui::tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);
        let tier = calculate_tier(amount);
        let multiplier = calculate_allocation_multiplier(tier);

        let user_stake = UserStake {
            amount,
            tier,
            stake_time: current_time,
            rewards_earned: 0,
            allocation_multiplier: multiplier,
        };

        if (table::contains(&pool.user_stakes, user)) {
            let existing_stake = table::borrow_mut(&mut pool.user_stakes, user);
            existing_stake.amount = existing_stake.amount + amount;
            existing_stake.tier = calculate_tier(existing_stake.amount);
            existing_stake.allocation_multiplier = calculate_allocation_multiplier(existing_stake.tier);
        } else {
            table::add(&mut pool.user_stakes, user, user_stake);
        };

        balance::join(&mut pool.total_staked, coin::into_balance(tokens));

        event::emit(TokensStaked {
            user,
            amount,
            tier,
            timestamp: current_time,
        });
    }

    /// Unstake SUIX tokens
    public entry fun unstake_tokens(
        pool: &mut StakingPool,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let user = sui::tx_context::sender(ctx);
        assert!(table::contains(&pool.user_stakes, user), E_INSUFFICIENT_STAKE);
        
        let user_stake = table::borrow_mut(&mut pool.user_stakes, user);
        assert!(user_stake.amount >= amount, E_INSUFFICIENT_STAKE);
        
        user_stake.amount = user_stake.amount - amount;
        user_stake.tier = calculate_tier(user_stake.amount);
        user_stake.allocation_multiplier = calculate_allocation_multiplier(user_stake.tier);
        
        let withdrawn = balance::split(&mut pool.total_staked, amount);
        let coin = coin::from_balance(withdrawn, ctx);
        public_transfer(coin, user);
    }

    // ============ IDO Participation Functions ============

    /// Contribute to an IDO
    public entry fun contribute(
        launchpad: &mut Launchpad,
        staking_pool: &StakingPool,
        kyc_record: &KYCRecord,
        clock: &Clock,
        contribution: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        let user = sui::tx_context::sender(ctx);
        let contribution_amount = coin::value(&contribution);

        // Validation checks
        assert!(launchpad.is_active, E_IDO_NOT_ACTIVE);
        assert!(current_time >= launchpad.start_time, E_IDO_NOT_STARTED);
        assert!(current_time <= launchpad.end_time, E_IDO_ENDED);
        
        if (launchpad.kyc_required) {
            assert!(kyc_record.verified && kyc_record.user == user, E_KYC_NOT_COMPLETED);
        };

        assert!(contribution_amount >= launchpad.min_contribution, E_CONTRIBUTION_LIMITS);
        assert!(contribution_amount <= launchpad.max_contribution, E_CONTRIBUTION_LIMITS);

        // Calculate token allocation based on staking tier
        let allocation_multiplier = if (table::contains(&staking_pool.user_stakes, user)) {
            let user_stake = table::borrow(&staking_pool.user_stakes, user);
            user_stake.allocation_multiplier
        } else {
            1 // Base multiplier for non-stakers
        };

        let base_tokens = (contribution_amount * 1000000) / launchpad.token_price; // Assuming 6 decimals
        let token_allocation = base_tokens * allocation_multiplier;

        // Create allocation record
        let allocation = Allocation {
            id: sui::object::new(ctx),
            launchpad_id: sui::object::id(launchpad),
            user,
            contributed_amount: contribution_amount,
            token_allocation,
            claimed: false,
            refunded: false,
            contribution_time: current_time,
        };

        // Update launchpad state
        balance::join(&mut launchpad.raised_amount, coin::into_balance(contribution));
        launchpad.total_contributors = launchpad.total_contributors + 1;

        event::emit(IDOContribution {
            launchpad_id: sui::object::id(launchpad),
            user,
            amount: contribution_amount,
            token_allocation,
            timestamp: current_time,
        });

        public_transfer(allocation, user);
    }

    /// Claim allocated tokens after IDO ends
    public entry fun claim_tokens(
        launchpad: &Launchpad,
        allocation: &mut Allocation,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        let user = sui::tx_context::sender(ctx);

        assert!(allocation.user == user, E_NOT_AUTHORIZED);
        assert!(!allocation.claimed, E_ALREADY_CLAIMED);
        assert!(!allocation.refunded, E_ALREADY_REFUNDED);
        assert!(current_time > launchpad.end_time, E_IDO_NOT_STARTED);
        assert!(allocation.launchpad_id == sui::object::id(launchpad), E_NOT_AUTHORIZED);

        allocation.claimed = true;

        event::emit(TokensClaimed {
            launchpad_id: sui::object::id(launchpad),
            user,
            amount: allocation.token_allocation,
            timestamp: current_time,
        });

        // Note: In a complete implementation, you would transfer the actual project tokens here
        // This requires integration with the project's token contract
    }

    /// Request refund (when enabled)
    public entry fun request_refund(
        launchpad: &mut Launchpad,
        allocation: &mut Allocation,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        let user = sui::tx_context::sender(ctx);

        assert!(launchpad.refund_enabled, E_REFUND_NOT_ENABLED);
        assert!(allocation.user == user, E_NOT_AUTHORIZED);
        assert!(!allocation.claimed, E_ALREADY_CLAIMED);
        assert!(!allocation.refunded, E_ALREADY_REFUNDED);
        assert!(allocation.launchpad_id == sui::object::id(launchpad), E_NOT_AUTHORIZED);

        allocation.refunded = true;
        let refund_amount = allocation.contributed_amount;

        // Transfer refund to user
        let refund = balance::split(&mut launchpad.raised_amount, refund_amount);
        let refund_coin = coin::from_balance(refund, ctx);
        public_transfer(refund_coin, user);

        event::emit(RefundIssued {
            launchpad_id: sui::object::id(launchpad),
            user,
            amount: refund_amount,
            timestamp: current_time,
        });
    }

    // ============ Helper Functions ============

    /// Calculate user tier based on staked amount
    fun calculate_tier(amount: u64): u8 {
        if (amount >= TIER_3_THRESHOLD) {
            3
        } else if (amount >= TIER_2_THRESHOLD) {
            2
        } else if (amount >= TIER_1_THRESHOLD) {
            1
        } else {
            0
        }
    }

    /// Calculate allocation multiplier based on tier
    fun calculate_allocation_multiplier(tier: u8): u64 {
        if (tier == 3) {
            5 // 5x multiplier for tier 3
        } else if (tier == 2) {
            3 // 3x multiplier for tier 2
        } else if (tier == 1) {
            2 // 2x multiplier for tier 1
        } else {
            1 // 1x multiplier for tier 0
        }
    }

    // ============ View Functions ============

    /// Get launchpad information
    public fun get_launchpad_info(launchpad: &Launchpad): (String, u64, u64, u64, bool) {
        (
            launchpad.project.name,
            launchpad.total_allocation,
            balance::value(&launchpad.raised_amount),
            launchpad.total_contributors,
            launchpad.is_active
        )
    }

    /// Get user stake information
    public fun get_user_stake(pool: &StakingPool, user: address): (u64, u8, u64) {
        if (table::contains(&pool.user_stakes, user)) {
            let stake = table::borrow(&pool.user_stakes, user);
            (stake.amount, stake.tier, stake.allocation_multiplier)
        } else {
            (0, 0, 1)
        }
    }

    /// Get project vetting score
    public fun get_vetting_score(launchpad: &Launchpad): u8 {
        launchpad.project.vetting_score
    }

    /// Check if IDO is active
    public fun is_ido_active(launchpad: &Launchpad, clock: &Clock): bool {
        let current_time = clock::timestamp_ms(clock);
        launchpad.is_active && 
        current_time >= launchpad.start_time && 
        current_time <= launchpad.end_time
    }
}