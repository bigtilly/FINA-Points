import warnings
warnings.filterwarnings('ignore')

import pandas as pd
import numpy as np
import time
import random
from datetime import datetime
from SwimScraper import SwimScraper as ss

# ============================================================================ 
# CONFIGURATION AND CONSTANTS (from the notebook)
# ============================================================================ 
TARGET_SAMPLE_SIZE = 5
PRIORITY_EVENTS = ['100 Breast', '200 Breast', '100 Free', '200 Free']
CURRENT_YEAR = 2024
MIN_PER_DIVISION = 10
DEFAULT_ROSTER_SIZE = 25
RANDOM_SEED = 42
GENDER = 'M' # Mens teams only

# Set random seeds for reproducibility
random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

# ============================================================================ 
# HELPER FUNCTIONS (from the notebook)
# ============================================================================ 

def time_to_seconds(time_str):
    """Convert swimming time string (MM:SS.ss or SS.ss) to seconds"""
    try:
        if ':' in str(time_str):
            parts = str(time_str).split(':')
            minutes = float(parts[0])
            seconds = float(parts[1])
            return minutes * 60 + seconds
        else:
            return float(time_str)
    except (ValueError, TypeError):
        return 9999.99

def safe_api_call(func, *args, **kwargs):
    """Wrapper for API calls with error handling and debug logging"""
    try:
        # Add a small random delay to be less predictable
        time.sleep(random.uniform(0.5, 1.5))
        result = func(*args, **kwargs)
        return result
    except Exception as e:
        print(f"[ERROR] API call {func.__name__} failed. Args: {args}, Kwargs: {kwargs}. Error: {e}")
        return None

def collect_swimmer_data(swimmer, team_name, team_id, division):
    """Collect times for a single swimmer in priority events"""
    if not swimmer or not isinstance(swimmer, dict):
        print(f"  [WARN] Invalid swimmer object for team {team_name} ({team_id})")
        return None

    swimmer_id = swimmer.get('swimmer_ID')
    swimmer_name = swimmer.get('swimmer_name', 'Unknown')

    swimmer_data = {
        'swimmer_ID': swimmer_id,
        'swimmer_name': swimmer_name,
        'team_name': team_name,
        'team_ID': team_id,
        'division': division,
        'times': {}
    }

    print(f"    - Collecting data for swimmer: {swimmer_name} (ID: {swimmer_id})")

    for event in PRIORITY_EVENTS:
        times = safe_api_call(ss.getSwimmerTimes, swimmer_ID=swimmer_id, event=event)
        if not times:
            continue

        try:
            # Pick season best
            season_best = min(times, key=lambda x: time_to_seconds(x.get('time', '99:99.99')))
            time_seconds = time_to_seconds(season_best.get('time'))
            if time_seconds < 999:
                swimmer_data['times'][event] = {
                    'time_str': season_best.get('time'),
                    'time_seconds': time_seconds,
                    'meet_name': season_best.get('meet_name', ''),
                    'year': season_best.get('year', '')
                }
        except Exception as e:
            print(f"      [ERROR] Processing times failed for {swimmer_name} ({event}): {e}")
            continue

    return swimmer_data if swimmer_data['times'] else None

# ============================================================================ 
# DATA COLLECTION FUNCTIONS (rewritten from notebook)
# ============================================================================ 

def get_division_team_data():
    """Fetch all teams in each division and estimate their roster sizes."""
    divisions = {'Division 1': [], 'Division 2': [], 'Division 3': [], 'NAIA': []}
    for div in divisions.keys():
        print(f"\nFetching teams for {div}...")
        teams = safe_api_call(ss.getCollegeTeams, division_names=[div])
        if not teams:
            print(f"[WARN] Could not fetch teams for {div}.")
            continue

        for i, t in enumerate(teams):
            team_id = t.get('team_ID')
            team_name = t.get('team_name')
            print(f"  - Processing team {i+1}/{len(teams)}: {team_name} (ID: {team_id})")

            roster = safe_api_call(ss.getRoster, team=team_name, team_ID=team_id, gender=GENDER, year=CURRENT_YEAR)
            roster_size = len(roster) if roster else DEFAULT_ROSTER_SIZE
            
            divisions[div].append({"team_ID": team_id, "team_name": team_name, "roster_size": roster_size})
            
    return divisions

def compute_division_targets(divisions, total_sample_size):
    """Compute how many swimmers to sample from each division."""
    est_counts = {div: sum(t['roster_size'] for t in teams) for div, teams in divisions.items()}
    total_swimmers = sum(est_counts.values())
    
    if total_swimmers == 0:
        print("[ERROR] No swimmers found across all divisions. Cannot compute targets.")
        return {div: 0 for div in divisions.keys()}

    targets = {
        div: max(int(round((count / total_swimmers) * total_sample_size)), MIN_PER_DIVISION if count > 0 else 0)
        for div, count in est_counts.items()
    }

    # Normalize to match the target sample size
    current_total = sum(targets.values())
    diff = total_sample_size - current_total
    
    while diff != 0:
        # Add or remove from the largest divisions first
        for div in sorted(targets, key=lambda d: est_counts[d], reverse=True):
            if diff == 0: break
            if diff > 0:
                targets[div] += 1
                diff -= 1
            elif diff < 0 and targets[div] > MIN_PER_DIVISION:
                targets[div] -= 1
                diff += 1
    
    print(f"\nComputed sample targets per division: {targets}")
    return targets

def allocate_team_samples(teams, div_target):
    """Allocate a specific number of samples to teams within a division."""
    total_roster = sum(t['roster_size'] for t in teams)
    if total_roster == 0: return []

    allocations = []
    for t in teams:
        proportion = t['roster_size'] / total_roster
        num_swimmers = int(round(proportion * div_target))
        # Ensure we don't try to sample more swimmers than are on the roster
        num_swimmers = min(num_swimmers, t['roster_size'])
        allocations.append((t, num_swimmers))

    # Adjust rounding to match the target
    current_total = sum(count for _, count in allocations)
    diff = div_target - current_total
    
    idx = 0
    while diff != 0 and allocations:
        team, count = allocations[idx % len(allocations)]
        
        if diff > 0:
            if count < team['roster_size']:
                allocations[idx % len(allocations)] = (team, count + 1)
                diff -= 1
        elif diff < 0:
            if count > 0:
                allocations[idx % len(allocations)] = (team, count - 1)
                diff += 1
        idx += 1

    return [(t, count) for t, count in allocations if count > 0]


def run_data_collection():
    """Main function to run the stratified data collection process."""
    print("="*60)
    print("STARTING STRATIFIED AND PROPORTIONAL DATA COLLECTION")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*60)

    start_time = time.time()
    all_swimmers_data = []

    # 1. Get all teams and their estimated roster sizes
    divisions_with_teams = get_division_team_data()

    # 2. Compute how many swimmers to get from each division
    division_targets = compute_division_targets(divisions_with_teams, TARGET_SAMPLE_SIZE)

    # 3. Collect data for each division
    for div, div_target in division_targets.items():
        teams_in_div = divisions_with_teams[div]
        if not teams_in_div or div_target <= 0:
            continue

        print(f"\n--- Collecting {div_target} swimmers from {len(teams_in_div)} teams in {div} ---")

        # Special handling for D1 to get a stratified sample of teams
        if div == 'Division 1':
            print("  - Getting D1 team rankings for stratification...")
            ranked_teams = safe_api_call(ss.getTeamRankingsList, gender=GENDER, year=CURRENT_YEAR)
            if ranked_teams:
                # Estimate how many teams we need to hit our target
                est_teams_needed = max(1, div_target // 10) # Assuming ~10 swimmers per team
                step_size = max(1, len(ranked_teams) // est_teams_needed)
                print(f"  - D1 stratified step size = {step_size} (sampling ~{len(ranked_teams[::step_size])} teams)")
                
                # Get team info for the selected ranked teams
                d1_team_ids = {t['team_ID'] for t in ranked_teams[::step_size]}
                teams_to_sample_from = [t for t in teams_in_div if t['team_ID'] in d1_team_ids]
            else:
                print("  - [WARN] Could not get D1 rankings. Using random sample of D1 teams instead.")
                # Fallback to random sampling if rankings fail
                num_to_sample = max(1, div_target // 10)
                teams_to_sample_from = random.sample(teams_in_div, min(num_to_sample, len(teams_in_div)))
        else:
            # For other divisions, just take a random sample of teams
            num_to_sample = max(1, div_target // 10)
            teams_to_sample_from = random.sample(teams_in_div, min(num_to_sample, len(teams_in_div)))
        
        # 4. Allocate swimmer counts to the selected teams
        team_allocations = allocate_team_samples(teams_to_sample_from, div_target)
        
        # 5. Get swimmer data
        div_swimmers_collected = []
        for team_entry, num_to_collect in team_allocations:
            if len(div_swimmers_collected) >= div_target: break

            team_id = team_entry.get("team_ID")
            team_name = team_entry.get("team_name")
            
            print(f"\n  - Getting {num_to_collect} swimmer(s) from {team_name}...")
            roster = safe_api_call(ss.getRoster, team_ID=team_id, gender=GENDER, year=CURRENT_YEAR)
            if not roster:
                print(f"    [SKIP] Could not fetch roster for {team_name} ({team_id}).")
                continue

            # Take a random sample of swimmers from the roster
            swimmers_to_sample = random.sample(roster, min(num_to_collect, len(roster)))

            for swimmer in swimmers_to_sample:
                if len(div_swimmers_collected) >= div_target: break
                
                swimmer_data = collect_swimmer_data(swimmer, team_name, team_id, div)
                if swimmer_data:
                    div_swimmers_collected.append(swimmer_data)
        
        all_swimmers_data.extend(div_swimmers_collected)
        print(f"\n✓ {div} Complete: Collected data for {len(div_swimmers_collected)} swimmers.")

    elapsed = (time.time() - start_time) / 60
    print("\n" + "="*60)
    print("DATA COLLECTION COMPLETE")
    print(f"Total swimmers with data collected: {len(all_swimmers_data)} in {elapsed:.1f} minutes.")
    print("="*60)
    
    return all_swimmers_data


if __name__ == "__main__":
    # Run the data collection
    raw_data = run_data_collection()

    if raw_data:
        # Flatten the data and save to a CSV
        records = []
        for swimmer in raw_data:
            for event, time_data in swimmer['times'].items():
                record = {
                    'swimmer_ID': swimmer['swimmer_ID'],
                    'swimmer_name': swimmer['swimmer_name'],
                    'team_name': swimmer['team_name'],
                    'division': swimmer['division'],
                    'event': event,
                    'time_seconds': time_data['time_seconds'],
                    'time_str': time_data['time_str'],
                    'meet_name': time_data['meet_name'],
                    'year': time_data['year']
                }
                records.append(record)
        
        df = pd.DataFrame(records)
        output_filename = f"swimmer_data_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        df.to_csv(output_filename, index=False)
        print(f"\nSuccessfully saved data for {len(df)} swims to {output_filename}")
    else:
        print("\nNo data was collected. The script has finished.")
