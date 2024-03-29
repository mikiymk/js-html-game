const std = @import("std");
const builtin = @import("builtin");

const bit_board = @import("../bit-board/main.zig");

// 1 << n
//
//  63 62 61 60 59 58 57 56
//  55 54 53 52 51 50 49 48
//  47 46 45 44 43 42 41 40
//  39 38 37 36 35 34 33 32
//  31 30 29 28 27 26 25 24
//  23 22 21 20 19 18 17 16
//  15 14 13 12 11 10  9  8
//   7  6  5  4  3  2  1  0

const Board = @This();

// properties

/// 黒のビットボード
black: u64 = 0,

/// 白のビットボード
white: u64 = 0,

/// 次に打つ色
nextColor: Color = .black,

/// プレイヤーの色のリスト。黒か白か
pub const Color = enum(u1) {
    black,
    white,

    /// 黒なら白、白なら黒。
    /// 現在の逆の色を返す
    pub fn turn(c: Color) Color {
        return switch (c) {
            .black => .white,
            .white => .black,
        };
    }
};

/// ボードの初期状態を作る
pub fn init() Board {
    return fromString(
        \\........
        \\........
        \\........
        \\...xo...
        \\...ox...
        \\........
        \\........
        \\........
    );
}

/// 現在のプレイヤー側のビットボードを取得する
pub fn getPlayer(b: Board) u64 {
    return switch (b.nextColor) {
        .black => b.black,
        .white => b.white,
    };
}

/// 現在の相手側のビットボードを取得する
pub fn getOpponent(b: Board) u64 {
    return switch (b.nextColor) {
        .black => b.white,
        .white => b.black,
    };
}

/// 場所に置いた時、ひっくり返す石を求める
fn getFlipSquares(b: Board, place: u64) u64 {
    const player_board: u64 = b.getPlayer();
    const opponent_board: u64 = b.getOpponent();

    const mask: u64 = opponent_board & bit_board.fromString(
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
    , 'o');

    var flip: u64 =
        // 横方向を探索する
        moveDir(player_board, place, mask, 1) |
        // 縦方向を探索する
        moveDir(player_board, place, opponent_board, 8) |
        // 右上-左下方向を探索する
        moveDir(player_board, place, mask, 7) |
        // 左上-右下方向を探索する
        moveDir(player_board, place, mask, 9);

    return flip;
}

/// Placeで示された場所に石を置く。
/// 既に置いてある石でひっくり返す石がある場合は、それをひっくり返す。
/// ボードを更新する
pub fn moveMutate(b: *Board, place: u64) void {
    const flip = b.getFlipSquares(place);

    b.black ^= flip;
    b.white ^= flip;
    if (b.nextColor == .black) {
        b.black |= place;
    } else {
        b.white |= place;
    }
}

/// Placeで示された場所に石を置く。
/// 既に置いてある石でひっくり返す石がある場合は、それをひっくり返す。
/// ボードを更新する
pub fn move(b: Board, place: u64) Board {
    const flip = b.getFlipSquares(place);

    var black = b.black ^ flip;
    var white = b.white ^ flip;

    if (b.nextColor == .black) {
        black |= place;
    } else {
        white |= place;
    }

    var new_board = Board{
        .black = black,
        .white = white,
        .nextColor = b.nextColor.turn(),
    };

    if (new_board.getValidMoves() == 0) {
        new_board.nextColor = new_board.nextColor.turn();
    }

    return new_board;
}

/// Dirで示された方向の前後にひっくり返す石を探す。
fn moveDir(player_board: u64, place: u64, mask: u64, dir: u6) u64 {

    // MSB側の探索
    var flip_m: u64 = (place << dir) & mask;
    flip_m |= (flip_m << dir) & mask;
    flip_m |= (flip_m << dir) & mask;
    flip_m |= (flip_m << dir) & mask;
    flip_m |= (flip_m << dir) & mask;
    flip_m |= (flip_m << dir) & mask;

    // LSB側の探索
    var flip_l: u64 = (place >> dir) & mask;
    flip_l |= (flip_l >> dir) & mask;
    flip_l |= (flip_l >> dir) & mask;
    flip_l |= (flip_l >> dir) & mask;
    flip_l |= (flip_l >> dir) & mask;
    flip_l |= (flip_l >> dir) & mask;

    // 返せる石
    var flip: u64 = 0;

    if (player_board & (flip_m << dir) != 0) {
        // もしMSB側の先にプレイヤーの石があれば、ひっくり返せる
        flip |= flip_m;
    }
    if (player_board & (flip_l >> dir) != 0) {
        // もしLSB側の先にプレイヤーの石があれば、ひっくり返せる
        flip |= flip_l;
    }

    return flip;
}

test "move black" {
    const testing = std.testing;

    var board = fromString(
        \\o..o..o.
        \\.x.x.x..
        \\..xxx...
        \\oxx.xxxo
        \\..xxx...
        \\.x.x.x..
        \\o..x..x.
        \\...o...o
    );

    const place = bit_board.fromString(
        \\........
        \\........
        \\........
        \\...o....
        \\........
        \\........
        \\........
        \\........
    , 'o');

    const expected = fromString(
        \\o..o..o.
        \\.o.o.o..
        \\..ooo...
        \\oooooooo
        \\..ooo...
        \\.o.o.o..
        \\o..o..o.
        \\...o...o
    );

    board.moveMutate(place);

    try testing.expectEqualDeep(expected, board);
}

/// 石を置ける場所のリストを作成する
pub fn getValidMoves(b: Board) u64 {
    const player_board = b.getPlayer();
    const opponent_board = b.getOpponent();

    const mask: u64 = opponent_board & bit_board.fromString(
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
    , 'o');

    return (getDirMoves(player_board, mask, 1) |
        getDirMoves(player_board, opponent_board, 8) |
        getDirMoves(player_board, mask, 7) |
        getDirMoves(player_board, mask, 9)) &
        ~(player_board | opponent_board);
}

/// Dirで示された方向に挟める場所を探す
fn getDirMoves(board: u64, mask: u64, dir: u6) u64 {
    var flip: u64 = board;
    flip = ((flip << dir) | (flip >> dir)) & mask;
    flip |= ((flip << dir) | (flip >> dir)) & mask;
    flip |= ((flip << dir) | (flip >> dir)) & mask;
    flip |= ((flip << dir) | (flip >> dir)) & mask;
    flip |= ((flip << dir) | (flip >> dir)) & mask;
    flip |= ((flip << dir) | (flip >> dir)) & mask;
    return (flip << dir) | (flip >> dir);
}

test "get valid move" {
    const testing = std.testing;

    // 現在のボード状態
    const board = fromString(
        \\...x..x.
        \\.x.x.x..
        \\..xxx...
        \\.xxoxxxx
        \\...x....
        \\.x.x.x..
        \\.xxxxxxo
        \\........
    );

    // マスク
    // 相手の石があるところだけ + 端をループしないように止める
    const mask: u64 = board.white & bit_board.fromString(
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
        \\.oooooo.
    , 'o');

    try testing.expectEqualStrings(
        \\...x..x.
        \\.x.x.x..
        \\..xxx...
        \\.xx.xxx.
        \\...x....
        \\.x.x.x..
        \\.xxxxxx.
        \\........
    , &bit_board.toString(mask, 'x', '.'));

    var flip = board.black;
    const dir = 1;

    try testing.expectEqualStrings(
        \\........
        \\........
        \\........
        \\...o....
        \\........
        \\........
        \\.......o
        \\........
    , &bit_board.toString(flip, 'o', '.'));

    // dirで決められた方向に向けて石を置く
    // 正の方向と負の方向の2方向を同時に進める
    flip = ((flip << dir) | (flip >> dir)) & mask;

    try testing.expectEqualStrings(
        \\........
        \\........
        \\........
        \\..o.o...
        \\........
        \\........
        \\......o.
        \\........
    , &bit_board.toString(flip, 'o', '.'));

    // さらに進めたものを前回のものとORで重ねる
    flip |= ((flip << dir) | (flip >> dir)) & mask;

    try testing.expectEqualStrings(
        \\........
        \\........
        \\........
        \\.oo.oo..
        \\........
        \\........
        \\.....oo.
        \\........
    , &bit_board.toString(flip, 'o', '.'));

    // 合計で6回進める
    flip |= ((flip << dir) | (flip >> dir)) & mask;
    flip |= ((flip << dir) | (flip >> dir)) & mask;
    flip |= ((flip << dir) | (flip >> dir)) & mask;
    flip |= ((flip << dir) | (flip >> dir)) & mask;

    try testing.expectEqualStrings(
        \\........
        \\........
        \\........
        \\.oo.ooo.
        \\........
        \\........
        \\.oooooo.
        \\........
    , &bit_board.toString(flip, 'o', '.'));

    // 最後にマスクなしで進める
    // 自分の石の隣に相手の石が繋がっているものの一番先頭

    flip = (flip << dir) | (flip >> dir);

    try testing.expectEqualStrings(
        \\........
        \\........
        \\........
        \\oooooooo
        \\........
        \\........
        \\oooooooo
        \\........
    , &bit_board.toString(flip, 'o', '.'));

    // これを「石が置かれていない場所」でマスク
    flip = flip & ~(board.black | board.white);

    try testing.expectEqualStrings(
        \\........
        \\........
        \\........
        \\o.......
        \\........
        \\........
        \\o.......
        \\........
    , &bit_board.toString(flip, 'o', '.'));

    // これを縦横斜めの4方向に向ける
    const moves = board.getValidMoves();

    try testing.expectEqualStrings(
        \\o.......
        \\........
        \\........
        \\o.......
        \\........
        \\........
        \\o.......
        \\...o....
    , &bit_board.toString(moves, 'o', '.'));
}

test "get valid move 1" {
    const testing = std.testing;

    const board = fromString(
        \\.ox.....
        \\........
        \\........
        \\.oxxx...
        \\........
        \\......ox
        \\........
        \\oxxxxxx.
    );
    const actual = bit_board.toString(board.getValidMoves(), 'o', '.');

    const expected =
        \\...o....
        \\........
        \\........
        \\.....o..
        \\........
        \\........
        \\........
        \\.......o
    ;

    try testing.expectEqualStrings(expected, &actual);
}

test "get valid move 2" {
    const testing = std.testing;

    const board = fromString(
        \\.o...x..
        \\.x.o.o.x
        \\...x...x
        \\...x...x
        \\...x...x
        \\o......x
        \\.......x
        \\.......o
    );
    const actual = bit_board.toString(board.getValidMoves(), 'o', '.');

    const expected =
        \\.......o
        \\........
        \\.o......
        \\........
        \\........
        \\...o....
        \\........
        \\........
    ;

    try testing.expectEqualStrings(expected, &actual);
}

test "get valid move 3" {
    const testing = std.testing;

    const board = fromString(
        \\o.......
        \\.x...o..
        \\..x...x.
        \\...x....
        \\....x...
        \\.x...x..
        \\..x...x.
        \\o..o....
    );
    const actual = bit_board.toString(board.getValidMoves(), 'o', '.');

    const expected =
        \\........
        \\........
        \\........
        \\.......o
        \\o.......
        \\........
        \\........
        \\.......o
    ;

    try testing.expectEqualStrings(expected, &actual);
}

test "get valid move 4" {
    const testing = std.testing;

    const board = fromString(
        \\..x.....
        \\.x....x.
        \\o....x..
        \\....x..o
        \\...x..x.
        \\..x..x..
        \\.x..x...
        \\o.......
    );
    const actual = bit_board.toString(board.getValidMoves(), 'o', '.');

    const expected =
        \\.......o
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\...o....
    ;

    try testing.expectEqualStrings(expected, &actual);
}

/// ゲームが終了しているか判定する。
/// どちらのプレイヤーも置く場所がなかったら終了
pub fn isEnd(b: Board) bool {
    if (b.getValidMoves() != 0) {
        return false;
    }

    const pass_board = Board{
        .black = b.black,
        .white = b.white,
        .nextColor = b.nextColor.turn(),
    };

    return pass_board.getValidMoves() == 0;
}

test "game is end" {
    const testing = std.testing;

    const board = fromString(
        \\oooooooo
        \\xxxxxxxx
        \\oooooooo
        \\xxxxxxxx
        \\oooooooo
        \\xxxxxxxx
        \\oooooooo
        \\xxxxxxxx
    );

    const actual = board.isEnd();
    const expected = true;

    try testing.expectEqual(expected, actual);
}

test "game is not end" {
    const testing = std.testing;

    const board = fromString(
        \\oooooooo
        \\xxxxxxxx
        \\oooooooo
        \\xxxxxxxx
        \\ooo.oooo
        \\xxxxxxxx
        \\oooooooo
        \\xxxxxxxx
    );

    const actual = board.isEnd();
    const expected = false;

    try testing.expectEqual(expected, actual);
}

/// ボードの文字列からボード構造体を作る
/// oが黒石、xが白石、それ以外で空白を表す。
pub fn fromString(comptime str: []const u8) Board {
    return .{
        .black = bit_board.fromString(str, 'o'),
        .white = bit_board.fromString(str, 'x'),
    };
}

test "board from string" {
    const testing = std.testing;

    var expected = Board{
        .black = 0x00_00_00_00_00_aa_55_aa,
        .white = 0x55_aa_55_00_00_00_00_00,
    };
    var actual = fromString(
        \\.o.o.o.o
        \\o.o.o.o.
        \\.o.o.o.o
        \\........
        \\........
        \\x.x.x.x.
        \\.x.x.x.x
        \\x.x.x.x.
    );

    try testing.expectEqualDeep(expected, actual);
}
