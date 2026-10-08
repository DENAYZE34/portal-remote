//! Device pairing policy: with "paired only" on, a correct password is not enough,
//! the connecting device must have been paired while pairing was open.
//! Std-only so it can be tested alone: `rustc --test src/pairing.rs`.

pub const OPTION_PAIRED_ONLY: &str = "paired-only";
pub const OPTION_PAIRING_UNTIL: &str = "pairing-until";
pub const OPTION_PAIRED_PEERS: &str = "paired-peers";
pub const MAX_PAIRED: usize = 50;
/// How long the host keeps pairing open after the user turns it on.
pub const PAIRING_WINDOW_SECS: u64 = 300;

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Decision {
    /// Not enforced, or already paired.
    Allow,
    /// Pairing is open: let this device in and remember it.
    AllowAndPair,
    /// Correct password but unknown device and pairing is closed.
    Deny,
}

pub fn parse_list(list: &str) -> Vec<String> {
    list.split(',')
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(|s| s.to_owned())
        .collect()
}

pub fn is_paired(list: &str, id: &str) -> bool {
    !id.is_empty() && parse_list(list).iter().any(|x| x == id)
}

/// Adds [id], keeping the newest [MAX_PAIRED].
pub fn add(list: &str, id: &str) -> String {
    let mut v = parse_list(list);
    if id.is_empty() || id.contains(',') {
        return v.join(",");
    }
    v.retain(|x| x != id);
    v.push(id.to_owned());
    if v.len() > MAX_PAIRED {
        let extra = v.len() - MAX_PAIRED;
        v.drain(0..extra);
    }
    v.join(",")
}

pub fn remove(list: &str, id: &str) -> String {
    let mut v = parse_list(list);
    v.retain(|x| x != id);
    v.join(",")
}

/// Pairing is open while [until_secs] (unix time) is in the future.
pub fn pairing_open(until_secs: &str, now: u64) -> bool {
    until_secs.trim().parse::<u64>().map(|u| u > now).unwrap_or(false)
}

/// Value to store in `pairing-until` to open pairing from [now].
pub fn open_until(now: u64) -> String {
    (now + PAIRING_WINDOW_SECS).to_string()
}

pub fn decide(paired_only: bool, list: &str, id: &str, until_secs: &str, now: u64) -> Decision {
    if !paired_only || is_paired(list, id) {
        return Decision::Allow;
    }
    if !id.is_empty() && pairing_open(until_secs, now) {
        Decision::AllowAndPair
    } else {
        Decision::Deny
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn not_enforced_always_allows() {
        assert_eq!(decide(false, "", "123", "", 1000), Decision::Allow);
    }

    #[test]
    fn paired_device_is_allowed_even_when_pairing_is_closed() {
        assert_eq!(decide(true, "111,222", "222", "", 1000), Decision::Allow);
    }

    #[test]
    fn unknown_device_is_denied_when_pairing_is_closed() {
        assert_eq!(decide(true, "111", "999", "", 1000), Decision::Deny);
        assert_eq!(decide(true, "111", "999", "900", 1000), Decision::Deny);
        assert_eq!(decide(true, "111", "999", "garbage", 1000), Decision::Deny);
    }

    #[test]
    fn unknown_device_is_paired_while_the_window_is_open() {
        assert_eq!(decide(true, "111", "999", "1200", 1000), Decision::AllowAndPair);
        // the window ends exactly at the stored time
        assert_eq!(decide(true, "111", "999", "1000", 1000), Decision::Deny);
    }

    #[test]
    fn empty_id_is_never_paired() {
        assert_eq!(decide(true, "", "", "9999", 1000), Decision::Deny);
        assert!(!is_paired("1,2", ""));
    }

    #[test]
    fn add_dedupes_and_caps() {
        assert_eq!(add("1,2", "2"), "1,2");
        assert_eq!(add("", "7"), "7");
        let mut l = String::new();
        for i in 0..(MAX_PAIRED + 5) {
            l = add(&l, &i.to_string());
        }
        let v = parse_list(&l);
        assert_eq!(v.len(), MAX_PAIRED);
        assert_eq!(v.last().unwrap(), &(MAX_PAIRED + 4).to_string());
        assert!(!is_paired(&l, "0"));
    }

    #[test]
    fn add_rejects_ids_that_would_break_the_list() {
        assert_eq!(add("1", "2,3"), "1");
        assert_eq!(add("1", ""), "1");
    }

    #[test]
    fn remove_unpairs_one_device() {
        assert_eq!(remove("1,2,3", "2"), "1,3");
        assert_eq!(remove("1", "9"), "1");
    }

    #[test]
    fn open_until_adds_the_window() {
        assert_eq!(open_until(1000), "1300");
        assert!(pairing_open(&open_until(1000), 1299));
        assert!(!pairing_open(&open_until(1000), 1300));
    }
}
