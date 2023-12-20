const std = @import("std");
const builtin = @import("builtin");

pub const Board = @import("Board.zig");
pub const Game = @import("Game.zig");
const PieceKind = Board.ColorPieceType;

/// アロケーター
const allocator = if (builtin.target.isWasm()) std.heap.wasm_allocator else std.heap.page_allocator;

extern fn random() f64;
fn getRamdom() f64 {
    return random();
}

/// ゲームを作成する
export fn init() ?*Game {
    const game_ptr = allocator.create(Game) catch return null;
    game_ptr.* = Game.init(allocator);

    return game_ptr;
}

/// ゲームを削除する
export fn deinit(g: ?*Game) void {
    if (g) |game_ptr| {
        allocator.destroy(game_ptr);
    }
}

/// ボードに駒を配置する
export fn setPiece(g: *Game, kind: PieceKind, index: u8) void {
    g.board.setPiece(kind, indexToPlace(index));
}

/// ボードの駒を取得する
export fn getPiece(g: *Game, kind: PieceKind) u64 {
    return g.board.getPieces(kind);
}

/// 今のターンが黒かどうか
export fn isBlack(g: *Game) bool {
    return g.next_color == .black;
}

/// ゲームが終了しているかどうか
export fn isEnd(g: *Game) bool {
    return g.ends(g.next_color) != null;
}

/// ゲームが終了している場合、勝利者を判定する
export fn winnter(g: *Game) u8 {
    return if (g.ends(g.next_color)) |result|
        switch (result) {
            .BlackWin => 1,
            .WhiteWin => 2,
            .Draw => 3,
        }
    else
        0;
}

/// 駒を選択し、その駒の移動先を取得する
export fn getMove(g: *Game, from_index: u8) u64 {
    const from_place = indexToPlace(from_index);

    return g.getMove(from_place);
}

/// 駒を移動する
/// アンパサン、キャスリングを判別する
/// 戻り値はプロモーションが可能かどうか
export fn move(g: *Game, from_index: u8, to_index: u8) bool {
    g.board = g.board.getMovedBoard(from_index, to_index);

    return false;
}

/// 駒のプロモーション
export fn promote(g: *Game, index: u8, piece_kind: PieceKind) void {
    _ = piece_kind;
    _ = index;
    _ = g;

    @panic("not implemented");
}

/// AIで駒を移動する
export fn moveAi(g: *Game) void {
    _ = g;

    @panic("not implemented");
}

fn indexToPlace(index: u8) u64 {
    return @as(u64, 1) << @as(u6, @truncate(index));
}

test {
    const testing = std.testing;

    testing.refAllDecls(@This());

    _ = @import("./Game_test.zig");
    _ = @import("./Board_test.zig");
    _ = @import("./moves_test.zig");
}
