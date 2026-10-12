extends Node
## EventBus — barramento global de sinais (evita acoplamento entre cenas).
## Autoload: EventBus

# --- Jogo / fluxo ---
signal state_changed(from_state: int, to_state: int)
signal stage_selected(stage_id: String)

# --- Simulação -> UI (reemitidos pela cena do jogo a partir dos SimEvents) ---
signal coins_changed(run_coins: int, bank_coins: int)
signal gems_changed(gems: int)
signal base_hp_changed(hp: int, max_hp: int)
signal wave_started(wave_index: int, wave_total: int)
signal wave_cleared(wave_index: int, wave_total: int)
signal boss_spawned(enemy_id: int, name_key: String)
signal boss_hp_changed(hp: float, max_hp: float, enraged: bool)
signal stage_won(stars: int)
signal stage_lost
signal merge_performed(from_slot: int, to_slot: int, new_tier: int)
signal buy_failed(reason: String)
signal enemy_killed(enemy_id: int, reward: int, is_boss: bool)
signal cat_bought(tier: int)
signal cat_sold(slot: int, refund: int)

# --- Configuração ---
signal sfx_changed(enabled: bool)
signal music_changed(enabled: bool)
signal vibration_changed(enabled: bool)
signal reduce_fx_changed(enabled: bool)
signal language_changed(locale: String)
signal text_scale_changed(scale: int)

func haptic(msec: int = 25) -> void:
	if GameSettings and GameSettings.vibration_enabled:
		Input.vibrate_handheld(msec)
