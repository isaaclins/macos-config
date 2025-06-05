#!/usr/bin/env bash
# Author: @isaaclins
# Date: 2025-06-05
# Version: 1.1.2
# Description: Encodes text into an ASCII QR code (Version 1-L, Byte Mode, placeholder ECC, fixed mask).
# Usage: echo 'text' | $0 OR $0 'text'

if [ -z "$BASH_VERSION" ] || [ "${BASH_VERSION%%.*}" -lt 4 ]; then
    echo "Error: This script requires Bash version 4.0 or later for associative arrays." >&2
    echo "Your Bash version is: $BASH_VERSION" >&2
    echo "If you have a newer bash (e.g., from Homebrew), you might need to change the shebang line" >&2
    echo "(the first line of this script) to point to it (e.g., #!/opt/homebrew/bin/bash or #!/usr/bin/env bash)." >&2
    exit 1
fi

# --- Constants for QR Version 1-L ---
QR_VERSION=1
QR_SIZE=21 # For Version 1 (21x21 modules)
DATA_CODEWORDS_V1L=19
EC_CODEWORDS_V1L=7
TOTAL_DATA_BITS_V1L=$((DATA_CODEWORDS_V1L * 8)) # 19 * 8 = 152 bits
TOTAL_EC_BITS_V1L=$((EC_CODEWORDS_V1L * 8))     # 7 * 8 = 56 bits
TOTAL_BITSTREAM_LENGTH=$((TOTAL_DATA_BITS_V1L + TOTAL_EC_BITS_V1L)) # 152 + 56 = 208 bits

# Max input bytes for V1-L Byte Mode, after mode/count indicators & terminator
# Mode (4) + Count (8) + Terminator (4) = 16 bits overhead from 152 data bits
# Remaining for actual data = 152 - 16 = 136 bits = 17 bytes
MAX_INPUT_BYTES_V1L=17

# Format Information for Version 1, ECC Level L (01), Mask Pattern 0 (000)
# Data: 01000 (L=01, mask=000). BCH(15,5) encoded & XORed with 101010000010010
# Result: 111011110000010 (15 bits)
FORMAT_INFO_V1L_M0="111011110000010"

# --- Matrix Initialization & Manipulation ---
# Declare QR matrix (0 for white, 1 for black, 2 for protected/set)
declare -A qr_matrix

# Initialize matrix with -1 (unset)
init_qr_matrix() {
    for r in $(seq 0 $((QR_SIZE - 1))); do
        for c in $(seq 0 $((QR_SIZE - 1))); do
            qr_matrix[$r,$c]=-1 # -1 for unset/available for data
        done
    done
}

# Set a module's color (and mark as protected)
# $1=row, $2=col, $3=color (0=white, 1=black)
set_module() {
    qr_matrix[$1,$2]=$3
}

# Place a pattern (e.g., finder pattern)
# $1=start_row, $2=start_col, $3=height, $4=width, $5=color (0 or 1)
place_rect() {
    local r_start=$1
    local c_start=$2
    local height=$3
    local width=$4
    local color=$5
    for r_offset in $(seq 0 $((height - 1))); do
        for c_offset in $(seq 0 $((width - 1))); do
            set_module $((r_start + r_offset)) $((c_start + c_offset)) $color
        done
    done
}

# --- QR Code Pattern Placement ---
place_finder_patterns() {
    # Top-left finder pattern (0,0) to (6,6)
    place_rect 0 0 7 7 1 # Outer 7x7 black
    place_rect 1 1 5 5 0 # Middle 5x5 white
    place_rect 2 2 3 3 1 # Inner 3x3 black
    # Separator for top-left finder (white)
    place_rect 0 7 8 1 0 # Vertical separator (col 7, rows 0-7)
    place_rect 7 0 1 7 0 # Horizontal separator (row 7, cols 0-6) - col 7 already covered

    # Top-right finder pattern (0, QR_SIZE-7) to (6, QR_SIZE-1)
    local tr_col_start=$((QR_SIZE - 7))
    place_rect 0 $tr_col_start 7 7 1
    place_rect 1 $((tr_col_start + 1)) 5 5 0
    place_rect 2 $((tr_col_start + 2)) 3 3 1
    # Separator for top-right finder (white)
    place_rect 0 $((QR_SIZE - 8)) 8 1 0 # Vertical separator (col QR_SIZE-8, rows 0-7)
    place_rect 7 $tr_col_start 1 7 0   # Horizontal separator (row 7, cols TR_START to QR_SIZE-1) - col QR_SIZE-8 already covered

    # Bottom-left finder pattern (QR_SIZE-7, 0) to (QR_SIZE-1, 6)
    local bl_row_start=$((QR_SIZE - 7))
    place_rect $bl_row_start 0 7 7 1
    place_rect $((bl_row_start + 1)) 1 5 5 0
    place_rect $((bl_row_start + 2)) 2 3 3 1
    # Separator for bottom-left finder (white)
    place_rect $bl_row_start 7 7 1 0   # Vertical separator (col 7, rows BL_START to QR_SIZE-1)
    place_rect $((QR_SIZE - 8)) 0 1 8 0 # Horizontal separator (row QR_SIZE-8, cols 0-7)
}

place_timing_patterns() {
    for i in $(seq 8 $((QR_SIZE - 8 -1))); do
        set_module 6 $i $((i % 2 == 0)) # Horizontal
        set_module $i 6 $((i % 2 == 0)) # Vertical
    done
}

place_dark_module() {
    set_module $((QR_SIZE - 8)) 8 1
}

place_format_information() {
    local fi_bits="$FORMAT_INFO_V1L_M0" # 15 bits "111011110000010"
    local bit_idx=0

    # --- First location: Around top-left finder pattern ---
    # FI[0]..FI[5] at (8,0)..(8,5)
    for c in 0 1 2 3 4 5; do
        set_module 8 $c "${fi_bits:$bit_idx:1}"
        bit_idx=$((bit_idx + 1))
    done
    # FI[6] at (8,7)
    set_module 8 7 "${fi_bits:$bit_idx:1}"
    bit_idx=$((bit_idx + 1))

    # FI[7] at (7,8)
    set_module 7 8 "${fi_bits:$bit_idx:1}"
    bit_idx=$((bit_idx + 1))

    # FI[8]..FI[13] at (5,8)..(0,8) (read upwards)
    for r in 5 4 3 2 1 0; do # 6 bits
        set_module $r 8 "${fi_bits:$bit_idx:1}"
        bit_idx=$((bit_idx + 1))
    done

    # FI[14] at (8,8)
    set_module 8 8 "${fi_bits:$bit_idx:1}"
    # bit_idx should be 15 here

    # --- Second location: Near top-right and bottom-left finders ---
    bit_idx=0 # Reset for full 15 bit string

    # FI[0]..FI[7] placed at (8, QR_SIZE-1) down to (8, QR_SIZE-8)
    # (8,20) (8,19) ... (8,13) for V1
    for i in $(seq 0 7); do # 8 bits: FI[0]..FI[7]
        set_module 8 $((QR_SIZE - 1 - i)) "${fi_bits:$bit_idx:1}"
        bit_idx=$((bit_idx + 1))
    done

    # FI[8]..FI[14] placed at (QR_SIZE-7, 8) up to (QR_SIZE-1, 8)
    # (14,8) (15,8) ... (20,8) for V1
    # This is 7 bits
    for i in $(seq 0 6); do # 7 bits: FI[8]..FI[14]
        set_module $((QR_SIZE - 7 + i)) 8 "${fi_bits:$bit_idx:1}"
        bit_idx=$((bit_idx + 1))
    done
}


# --- Data Encoding & Bitstream Preparation ---
decimal_to_binary_padded() {
    local value=$1
    local bit_length=$2
    local binary_string=""
    for (( i = bit_length - 1; i >= 0; i-- )); do
        if (( (value >> i) & 1 )); then binary_string+="1"; else binary_string+="0"; fi
    done
    echo "$binary_string"
}

prepare_final_bitstream() {
    local input_text="$1"
    local mode_indicator="0100" # Byte mode
    local byte_count=$(echo -n "$input_text" | wc -c | awk '{print $1}')
    local byte_count_indicator=$(decimal_to_binary_padded "$byte_count" 8) # 8-bit for V1-9

    local data_bits=""
    if [ "$byte_count" -gt 0 ]; then
        local hex_bytes=$(echo -n "$input_text" | xxd -p -c "$byte_count")
        local current_pos=0
        while [ "$current_pos" -lt "${#hex_bytes}" ]; do
            local hex_pair="${hex_bytes:$current_pos:2}"
            local decimal_val=$((16#$hex_pair))
            data_bits+=$(decimal_to_binary_padded "$decimal_val" 8)
            current_pos=$((current_pos + 2))
        done
    fi

    local combined_data_bits="${mode_indicator}${byte_count_indicator}${data_bits}"
    local bit_len=${#combined_data_bits}

    # Add terminator '0000' if space permits (always for V1 unless data is maxed out)
    if [ "$bit_len" -lt "$TOTAL_DATA_BITS_V1L" ]; then
        combined_data_bits+="0000"
        bit_len=$((bit_len + 4))
    fi

    # Pad to multiple of 8 bits
    if (( bit_len % 8 != 0 )); then
        local remainder=$((bit_len % 8))
        for _ in $(seq 1 $((8 - remainder))); do combined_data_bits+="0"; done
        bit_len=${#combined_data_bits}
    fi

    # Add pad bytes (11101100 and 00010001) until TOTAL_DATA_BITS_V1L is reached
    local pad_byte1="11101100"
    local pad_byte2="00010001"
    local use_pad1_cmd=true # Command 'true'
    while [ "$bit_len" -lt "$TOTAL_DATA_BITS_V1L" ]; do
        if $use_pad1_cmd; then combined_data_bits+="$pad_byte1"; else combined_data_bits+="$pad_byte2"; fi
        
        if $use_pad1_cmd; then # Toggle for next iteration
            use_pad1_cmd=false
        else
            use_pad1_cmd=true
        fi
        bit_len=$((bit_len + 8))
    done
    
    # Truncate if over (shouldn't happen with proper MAX_INPUT_BYTES_V1L check)
    combined_data_bits=${combined_data_bits:0:$TOTAL_DATA_BITS_V1L}

    # Placeholder Error Correction Codewords (all zeros)
    local ec_bits=""
    for _ in $(seq 1 "$TOTAL_EC_BITS_V1L"); do ec_bits+="0"; done

    echo "${combined_data_bits}${ec_bits}" # Total 208 bits for V1-L
}

# --- Data Placement & Masking ---
place_data_bits() {
    local bitstream="$1"
    local bit_idx=0
    local direction=-1 # -1 for up, 1 for down

    # Start from bottom-right, zig-zag upwards
    for c_base in $(seq $((QR_SIZE - 1)) -2 1); do # Iterate over double columns
        if [ "$c_base" -eq 7 ]; then c_base=6; fi # Skip vertical timing pattern column (col 6, not 7)

        for r_offset in $(seq 0 $((QR_SIZE - 1))); do
            local r
            if [ "$direction" -eq -1 ]; then r=$((QR_SIZE - 1 - r_offset)); else r=$r_offset; fi

            for c_offset in 0 1; do # Two columns in pair (right then left)
                local c=$((c_base - c_offset))
                if [ "${qr_matrix[$r,$c]}" -eq -1 ]; then # If module is unset (-1)
                    if [ "$bit_idx" -lt "${#bitstream}" ]; then
                        set_module $r $c "${bitstream:$bit_idx:1}"
                        bit_idx=$((bit_idx + 1))
                    else
                         # Ran out of bits, fill with 0 (white) as per spec for incomplete final byte if padding leads to this
                         set_module $r $c 0
                    fi
                fi
            done
        done
        direction=$((direction * -1)) # Change direction
    done
}

apply_mask_pattern0() {
    for r in $(seq 0 $((QR_SIZE - 1))); do
        for c in $(seq 0 $((QR_SIZE - 1))); do
            # Only apply mask if not a pre-set function pattern (original value was 0 or 1, not from place_rect)
            # A simpler check: if it's not a finder/timing/format area. This is complex to check perfectly.
            # For now, apply to all non-protected areas. Need to refine is_protected check.
            # The simplest is to check if qr_matrix[$r,$c] was not set by a pattern function.
            # This can be done by checking if it was 0 or 1 before masking, and not part of explicit format info.
            # A robust way is to re-check if (r,c) is part of any function pattern.
            # Quick check: skip if already a "protected" pattern (value > 1 or a predefined region)
            is_functional_pattern_area $r $c
            if [ $? -ne 0 ]; then # If not a functional pattern area
                if (((r + c) % 2 == 0)); then # Mask condition for pattern 0
                    if [ "${qr_matrix[$r,$c]}" = "1" ]; then
                        set_module $r $c 0 # Flip black to white
                    elif [ "${qr_matrix[$r,$c]}" = "0" ]; then
                        set_module $r $c 1 # Flip white to black
                    fi
                fi
            fi
        done
    done
}

# Dummy function, a real one would check if r,c is part of finders, timing, format info etc.
# Updated to better protect functional areas, especially Format Information.
is_functional_pattern_area() {
    local r=$1
    local c=$2
    # Finder patterns and separators (approx. 8x8 blocks)
    if { [ $r -lt 8 ] && [ $c -lt 8 ]; } || \
       { [ $r -lt 8 ] && [ $c -ge $((QR_SIZE - 8)) ]; } || \
       { [ $r -ge $((QR_SIZE - 8)) ] && [ $c -lt 8 ]; } || \
       # Timing patterns
       { [ $r -eq 6 ] && [ $c -ge 8 ] && [ $c -le $((QR_SIZE - 9)) ]; } || \
       { [ $c -eq 6 ] && [ $r -ge 8 ] && [ $r -le $((QR_SIZE - 9)) ]; } || \
       # Format Information Area 1 (around top-left finder)
       { [ $r -eq 8 ] && { [ $c -le 5 ] || [ $c -eq 7 ] || [ $c -eq 8 ]; }; } || \
       { [ $c -eq 8 ] && { [ $r -le 5 ] || [ $r -eq 7 ] || [ $r -eq 8 ]; }; } || # covers (8,8) and (x,8) (0-5,7)
       # Format Information Area 2 (top-right/bottom-left extensions)
       { [ $r -eq 8 ] && [ $c -ge $((QR_SIZE - 8)) ]; } || \
       { [ $c -eq 8 ] && [ $r -ge $((QR_SIZE - 7)) ]; } || 
       # Dark Module for V1 is (QR_SIZE-8, 8) = (13,8)
       { [ $r -eq $((QR_SIZE-8)) ] && [ $c -eq 8 ]; } then
        return 0 # Is functional
    fi
    return 1 # Not functional
}


# --- Output ---
print_qr_matrix() {
    local white_module="  " # Two spaces for white
    local black_module="██" # Block character for black

    echo "QR Code (Version 1-L, ASCII - Placeholder ECC):"
    for r in $(seq 0 $((QR_SIZE - 1))); do
        for c in $(seq 0 $((QR_SIZE - 1))); do
            if [ "${qr_matrix[$r,$c]}" = "1" ]; then
                printf "%s" "$black_module"
            else
                printf "%s" "$white_module"
            fi
        done
        printf "\\n" # Newline after each row
    done
}

# --- Main Script Logic ---
# 1. Determine input text
input_text=""
if [ -p /dev/stdin ]; then
    input_text=$(cat -)
elif [ -n "$1" ]; then
    input_text="$1"
else
    echo "Error: No input text provided." >&2
    echo "Usage: echo 'text' | $0 OR $0 'text'" >&2
    exit 1
fi

# 2. Validate input length for Version 1-L
byte_count=$(echo -n "$input_text" | wc -c | awk '{print $1}')
if [ "$byte_count" -gt "$MAX_INPUT_BYTES_V1L" ]; then
    echo "Error: Input text too long ($byte_count bytes). Max $MAX_INPUT_BYTES_V1L bytes for Version 1-L QR code." >&2
    exit 1
fi
if [ "$byte_count" -eq 0 ]; then
    echo "Error: Input text cannot be empty." >&2
    exit 1
fi


# 3. Prepare the full bitstream (data + placeholder ECC)
# This includes mode, count, data, terminator, padding
full_bitstream=$(prepare_final_bitstream "$input_text")
# echo "Debug: Full bitstream (${#full_bitstream} bits): $full_bitstream" # Optional debug

# 4. Initialize QR Matrix
init_qr_matrix

# 5. Place functional patterns
place_finder_patterns
place_timing_patterns
place_dark_module
# Format information is placed *after* masking typically, but we fix mask 0.
# So, we place it once, and then again after masking to ensure it's correct.
# However, our current format info is for mask 0. So one placement is fine.
# For a dynamic mask, this would be more complex.
# Let's place it now, assuming mask 0 is final.
place_format_information # For V1-L, Mask 0

# 6. Place data and EC bits
place_data_bits "$full_bitstream"

# 7. Apply mask pattern (Pattern 0)
apply_mask_pattern0

# 8. Re-place format information (as it depends on the mask, and mask application might flip its bits if not protected)
# To be robust, function patterns should ideally be "protected" from data filling and masking.
# My current set_module doesn't distinguish, and apply_mask_pattern0 has a simple check.
# For simplicity, as FORMAT_INFO_V1L_M0 is already for mask 0, and assuming place_format_information overwrites, this might be okay.
# A safer approach: clear format areas, apply mask, then place final format info.
# For now, the current `is_functional_pattern_area` in `apply_mask_pattern0` tries to prevent this.
# And `place_format_information` directly sets bits.

# 9. Print the ASCII QR Code
print_qr_matrix

echo ""
echo "Note: This is a Version 1-L QR code (21x21)."
echo "Error Correction is a PLACEHOLDER (all zeros) and a FIXED MASK (pattern 0) was used."
echo "The QR code may not be scannable by all readers due to these simplifications."

# Note: This script only performs the initial data encoding into a binary string.
# A full QR code generation involves many more steps, including:
# - Adding a terminator sequence (if needed and space allows, typically '0000').
# - Padding the bit string to a multiple of 8 bits.
# - Adding pad bytes (alternating 11101100 and 00010001) if the data capacity is not yet reached.
# - Structuring the data into blocks.
# - Generating error correction codewords.
# - Interleaving data and error correction codewords.
# - Placing the final bit pattern into the QR matrix along with finder patterns, alignment patterns, timing patterns, etc.
# The above comment block is from the previous version and needs update to reflect the new capabilities.
# The script now DOES attempt to place into a matrix with many of these patterns.
# Key missing piece for standard compliance is robust Reed-Solomon EC and mask evaluation.
