//! 8×8チェスボードの構造体。
//!

// std import
const std = @import("std");
const builtin = @import("builtin");

// common import
const common = @import("../common/main.zig");
const BitBoard = common.bit_board.BitBoard(8, 8);

// internal import
const main = @import("./main.zig");
const Board = main.Board;
const moves = main.moves;

// test import
test {
    _ = @import("./Board.test.zig");
}

pub const ColorPieceType = enum(u8) {
    black_pawn = 1,
    black_knight = 2,
    black_bishop = 3,
    black_rook = 4,
    black_queen = 5,
    black_king = 6,

    white_pawn = 7,
    white_knight = 8,
    white_bishop = 9,
    white_rook = 10,
    white_queen = 11,
    white_king = 12,

    pub fn fromColorType(c: Color, t: PieceType) ColorPieceType {
        return switch (c) {
            .black => switch (t) {
                .pawn => .black_pawn,
                .knight => .black_knight,
                .bishop => .black_bishop,
                .rook => .black_rook,
                .queen => .black_queen,
                .king => .black_king,
            },
            .white => switch (t) {
                .pawn => .white_pawn,
                .knight => .white_knight,
                .bishop => .white_bishop,
                .rook => .white_rook,
                .queen => .white_queen,
                .king => .white_king,
            },
        };
    }

    pub fn color(cp: ColorPieceType) Color {
        return switch (cp) {
            .black_pawn, .black_knight, .black_bishop, .black_rook, .black_queen, .black_king => .black,
            .white_pawn, .white_knight, .white_bishop, .white_rook, .white_queen, .white_king => .white,
        };
    }

    pub fn pieceType(cp: ColorPieceType) PieceType {
        return switch (cp) {
            .black_pawn, .white_pawn => .pawn,
            .black_knight, .white_knight => .knight,
            .black_bishop, .white_bishop => .bishop,
            .black_rook, .white_rook => .rook,
            .black_queen, .white_queen => .queen,
            .black_king, .white_king => .king,
        };
    }
};

pub const Color = enum {
    black,
    white,

    pub fn turn(color: Color) Color {
        return switch (color) {
            .black => .white,
            .white => .black,
        };
    }
};

pub const PieceType = enum {
    pawn,
    knight,
    bishop,
    rook,
    queen,
    king,
};

pub const position = struct {
    /// a8
    const black_rook_queenside = BitBoard.fromCoordinate(0, 7);
    /// b8
    const black_knight_queenside = BitBoard.fromCoordinate(1, 7);
    /// c8
    const black_bishop_queenside = BitBoard.fromCoordinate(2, 7);
    /// d8
    const black_queen = BitBoard.fromCoordinate(3, 7);
    /// e8
    const black_king = BitBoard.fromCoordinate(4, 7);
    /// f8
    const black_bishop_kingside = BitBoard.fromCoordinate(5, 7);
    /// g8
    const black_knight_kingside = BitBoard.fromCoordinate(6, 7);
    /// h8
    const black_rook_kingside = BitBoard.fromCoordinate(7, 7);

    /// a1
    const white_rook_queenside = BitBoard.fromCoordinate(0, 0);
    /// b1
    const white_knight_queenside = BitBoard.fromCoordinate(1, 0);
    /// c1
    const white_bishop_queenside = BitBoard.fromCoordinate(2, 0);
    /// d1
    const white_queen = BitBoard.fromCoordinate(3, 0);
    /// e1
    const white_king = BitBoard.fromCoordinate(4, 0);
    /// f1
    const white_bishop_kingside = BitBoard.fromCoordinate(5, 0);
    /// g1
    const white_knight_kingside = BitBoard.fromCoordinate(6, 0);
    /// h1
    const white_rook_kingside = BitBoard.fromCoordinate(7, 0);

    const black_square_mask = BitBoard.fromString(
        \\.o.o.o.o
        \\o.o.o.o.
        \\.o.o.o.o
        \\o.o.o.o.
        \\.o.o.o.o
        \\o.o.o.o.
        \\.o.o.o.o
        \\o.o.o.o.
    , 'o');
    const white_square_mask = BitBoard.fromString(
        \\o.o.o.o.
        \\.o.o.o.o
        \\o.o.o.o.
        \\.o.o.o.o
        \\o.o.o.o.
        \\.o.o.o.o
        \\o.o.o.o.
        \\.o.o.o.o
    , 'o');

    const final_ranks = BitBoard.fromString(
        \\oooooooo
        \\........
        \\........
        \\........
        \\........
        \\........
        \\........
        \\oooooooo
    , 'o');
};

black_pawn: BitBoard,
black_knight: BitBoard,
black_bishop: BitBoard,
black_rook: BitBoard,
black_queen: BitBoard,
black_king: BitBoard,

white_pawn: BitBoard,
white_knight: BitBoard,
white_bishop: BitBoard,
white_rook: BitBoard,
white_queen: BitBoard,
white_king: BitBoard,

/// アンパサンが可能ならその位置、それ以外では0
enpassant_target: BitBoard = BitBoard.init(),
/// キャスリングが可能かどうか
castling_available: struct {
    black_kingside: bool,
    black_queenside: bool,
    white_kingside: bool,
    white_queenside: bool,
} = .{
    .black_kingside = true,
    .black_queenside = true,
    .white_kingside = true,
    .white_queenside = true,
},

pub fn init() Board {
    return fromString(
        \\RNBQKBNR
        \\PPPPPPPP
        \\........
        \\........
        \\........
        \\........
        \\pppppppp
        \\rnbqkbnr
    );
}

pub fn fromString(str: []const u8) Board {
    return .{
        .black_pawn = BitBoard.fromString(str, 'P'),
        .black_knight = BitBoard.fromString(str, 'N'),
        .black_bishop = BitBoard.fromString(str, 'B'),
        .black_rook = BitBoard.fromString(str, 'R'),
        .black_queen = BitBoard.fromString(str, 'Q'),
        .black_king = BitBoard.fromString(str, 'K'),

        .white_pawn = BitBoard.fromString(str, 'p'),
        .white_knight = BitBoard.fromString(str, 'n'),
        .white_bishop = BitBoard.fromString(str, 'b'),
        .white_rook = BitBoard.fromString(str, 'r'),
        .white_queen = BitBoard.fromString(str, 'q'),
        .white_king = BitBoard.fromString(str, 'k'),
    };
}

/// 色と種類、追加する駒を指定し、チェスボードに駒を追加する。
pub fn setPiece(b: *Board, color_piece: ColorPieceType, pieces: BitBoard) void {
    switch (color_piece) {
        .black_pawn => b.black_pawn.setUnion(pieces),
        .black_knight => b.black_knight.setUnion(pieces),
        .black_bishop => b.black_bishop.setUnion(pieces),
        .black_rook => b.black_rook.setUnion(pieces),
        .black_queen => b.black_queen.setUnion(pieces),
        .black_king => b.black_king.setUnion(pieces),

        .white_pawn => b.white_pawn.setUnion(pieces),
        .white_knight => b.white_knight.setUnion(pieces),
        .white_bishop => b.white_bishop.setUnion(pieces),
        .white_rook => b.white_rook.setUnion(pieces),
        .white_queen => b.white_queen.setUnion(pieces),
        .white_king => b.white_king.setUnion(pieces),
    }
}

// 引数の色と種類からその色と種類のすべての駒の位置を返します。
pub fn getPieces(b: Board, color_piece: ColorPieceType) BitBoard {
    return switch (color_piece) {
        .black_pawn => b.black_pawn,
        .black_knight => b.black_knight,
        .black_bishop => b.black_bishop,
        .black_rook => b.black_rook,
        .black_queen => b.black_queen,
        .black_king => b.black_king,

        .white_pawn => b.white_pawn,
        .white_knight => b.white_knight,
        .white_bishop => b.white_bishop,
        .white_rook => b.white_rook,
        .white_queen => b.white_queen,
        .white_king => b.white_king,
    };
}

// 引数の色からその色のすべての駒の位置を返します。
pub fn getColorPieces(b: Board, color: Color) BitBoard {
    return switch (color) {
        .black => b.black_pawn
            .unions(b.black_knight)
            .unions(b.black_bishop)
            .unions(b.black_rook)
            .unions(b.black_queen)
            .unions(b.black_king),
        .white => b.white_pawn
            .unions(b.white_knight)
            .unions(b.white_bishop)
            .unions(b.white_rook)
            .unions(b.white_queen)
            .unions(b.white_king),
    };
}

// 場所からそこのマスにいるコマの色と種類を返します。
pub fn getColorType(b: Board, place: BitBoard) ?ColorPieceType {
    if (b.black_pawn.isJoint(place)) {
        return .black_pawn;
    } else if (b.black_knight.isJoint(place)) {
        return .black_knight;
    } else if (b.black_bishop.isJoint(place)) {
        return .black_bishop;
    } else if (b.black_rook.isJoint(place)) {
        return .black_rook;
    } else if (b.black_queen.isJoint(place)) {
        return .black_queen;
    } else if (b.black_king.isJoint(place)) {
        return .black_king;
    } else if (b.white_pawn.isJoint(place)) {
        return .white_pawn;
    } else if (b.white_knight.isJoint(place)) {
        return .white_knight;
    } else if (b.white_bishop.isJoint(place)) {
        return .white_bishop;
    } else if (b.white_rook.isJoint(place)) {
        return .white_rook;
    } else if (b.white_queen.isJoint(place)) {
        return .white_queen;
    } else if (b.white_king.isJoint(place)) {
        return .white_king;
    }

    return null;
}

// 場所からそこのマスにいるコマの色を返します。
pub fn getColor(b: Board, place: BitBoard) ?Color {
    return if (b.getColorType(place)) |color_type| color_type.color() else null;
}

// 場所からそこのマスにいるコマの種類を返します。
pub fn getType(b: Board, place: BitBoard) ?PieceType {
    return if (b.getColorType(place)) |color_type| color_type.pieceType() else null;
}

pub fn getMove(b: Board, from: BitBoard) BitBoard {
    const color_type = b.getColorType(from) orelse return BitBoard.init();

    const to_list = b.getNormalMove(from, color_type)
        .unions(b.getCastlingMove(from))
        .unions(b.getEnpassant(from, color_type.color()));

    return b.filterValidMove(from, to_list);
}

/// 通常の動きを取得する。
fn getNormalMove(b: Board, from: BitBoard, color_type: ColorPieceType) BitBoard {
    return switch (color_type.pieceType()) {
        .pawn => moves.pawn(b, from, color_type.color()),
        .knight => moves.knight(b, from, color_type.color()),
        .bishop => moves.bishop(b, from, color_type.color()),
        .rook => moves.rook(b, from, color_type.color()),
        .queen => moves.queen(b, from, color_type.color()),
        .king => moves.king(b, from, color_type.color()),
    };
}

fn getCastlingMove(b: Board, from: BitBoard) BitBoard {
    var board = BitBoard.init();
    if (from.eql(position.white_king)) {
        if (b.castling_available.white_kingside and b.canCastling(.white_king)) {
            board.setUnion(position.white_rook_kingside);
        }
        if (b.castling_available.white_queenside and b.canCastling(.white_queen)) {
            board.setUnion(position.white_rook_queenside);
        }
    } else if (from.eql(position.black_king)) {
        if (b.castling_available.black_kingside and b.canCastling(.black_king)) {
            board.setUnion(position.black_rook_kingside);
        }
        if (b.castling_available.black_queenside and b.canCastling(.black_queen)) {
            board.setUnion(position.black_rook_queenside);
        }
    }
    return board;
}

fn getEnpassant(b: Board, from: BitBoard, color: Color) BitBoard {
    if (switch (color) {
        .black => from.isJoint(b.black_pawn) and from.move(.se).unions(from.move(.sw)).isJoint(b.enpassant_target),
        .white => from.isJoint(b.white_pawn) and from.move(.ne).unions(from.move(.nw)).isJoint(b.enpassant_target),
    }) {
        return b.enpassant_target;
    } else {
        return BitBoard.init();
    }
}

/// プロモーションかどうかを判定する。
/// ポーンが最終ランクに到達したとき
pub fn isPromotion(b: Board, from: BitBoard, to: BitBoard) bool {
    return to.isJoint(position.final_ranks) and b.getType(from) == .pawn;
}

/// 現在の盤面でキャスリングが可能かどうかを判定する。
/// - キングとルークの間に駒がない
/// - キングの移動範囲が全て攻撃されていない
pub fn canCastling(b: Board, color_piece: ColorPieceType) bool {
    const black_king = position.black_king;
    const black_kingside_rook = position.black_rook_kingside;
    const black_queenside_rook = position.black_rook_queenside;

    const black_kingside_no_attacked = position.black_king.unions(position.black_bishop_kingside).unions(position.black_knight_kingside);
    const black_kingside_no_pieces = position.black_bishop_kingside.unions(position.black_knight_kingside);
    const black_queenside_no_attacked = position.black_bishop_queenside.unions(position.black_queen).unions(position.black_king);
    const black_queenside_no_pieces = position.black_knight_queenside.unions(position.black_bishop_queenside).unions(position.black_queen);

    const white_king = position.white_king;
    const white_kingside_rook = position.white_rook_kingside;
    const white_queenside_rook = position.white_rook_queenside;

    const white_kingside_no_attacked = position.white_king.unions(position.white_bishop_kingside).unions(position.white_knight_kingside);
    const white_kingside_no_pieces = position.white_bishop_kingside.unions(position.white_knight_kingside);
    const white_queenside_no_attacked = position.white_bishop_queenside.unions(position.white_queen).unions(position.white_king);
    const white_queenside_no_pieces = position.white_knight_queenside.unions(position.white_bishop_queenside).unions(position.white_queen);

    const pieces = b.getColorPieces(.black).unions(b.getColorPieces(.white));
    switch (color_piece) {
        .black_king => return b.black_king.isJoint(black_king) and
            b.black_rook.isJoint(black_kingside_rook) and
            pieces.isDisjoint(black_kingside_no_pieces) and
            !b.isAttacked(black_kingside_no_attacked, .black),

        .black_queen => return b.black_king.isJoint(black_king) and
            b.black_rook.isJoint(black_queenside_rook) and
            pieces.isDisjoint(black_queenside_no_pieces) and
            !b.isAttacked(black_queenside_no_attacked, .black),

        .white_king => return b.white_king.isJoint(white_king) and
            b.white_rook.isJoint(white_kingside_rook) and
            pieces.isDisjoint(white_kingside_no_pieces) and
            !b.isAttacked(white_kingside_no_attacked, .white),

        .white_queen => return b.white_king.isJoint(white_king) and
            b.white_rook.isJoint(white_queenside_rook) and
            pieces.isDisjoint(white_queenside_no_pieces) and
            !b.isAttacked(white_queenside_no_attacked, .white),

        else => return false,
    }
}

pub fn filterValidMove(b: Board, from: BitBoard, to_list: BitBoard) BitBoard {
    const from_color = b.getColor(from) orelse return BitBoard.init();

    var iter = to_list.iterator();
    var valid_board = BitBoard.init();
    while (iter.next()) |current| {
        // 動かしたボードがチェック状態の移動先を取り除く
        const moved_board = b.getMovedBoard(from, BitBoard.fromIndex(current));
        if (!moved_board.isChecked(from_color)) {
            valid_board.setUnion(BitBoard.fromIndex(current));
        }
    }

    return valid_board;
}

/// 盤がチェック状態になっているか
/// - color - チェックされるキングの色
pub fn isChecked(b: Board, color: Color) bool {
    if (color == .black) {
        return b.isAttacked(b.black_king, .black);
    } else {
        return b.isAttacked(b.white_king, .white);
    }
}

/// placeのマス目のうち1つ以上が攻撃されているかどうか。
/// 攻撃されているならばtrue。
fn isAttacked(b: Board, place: BitBoard, color: Color) bool {
    if (color == .black) {
        if (place.isJoint(moves.king(b, b.white_king, .white))) {
            return true;
        } else if (place.isJoint(moves.queen(b, b.white_queen, .white))) {
            return true;
        } else if (place.isJoint(moves.rook(b, b.white_rook, .white))) {
            return true;
        } else if (place.isJoint(moves.bishop(b, b.white_bishop, .white))) {
            return true;
        } else if (place.isJoint(moves.knight(b, b.white_knight, .white))) {
            return true;
        } else if (place.isJoint(moves.pawn(b, b.white_pawn, .white))) {
            return true;
        }
    } else {
        if (place.isJoint(moves.king(b, b.black_king, .black))) {
            return true;
        } else if (place.isJoint(moves.queen(b, b.black_queen, .black))) {
            return true;
        } else if (place.isJoint(moves.rook(b, b.black_rook, .black))) {
            return true;
        } else if (place.isJoint(moves.bishop(b, b.black_bishop, .black))) {
            return true;
        } else if (place.isJoint(moves.knight(b, b.black_knight, .black))) {
            return true;
        } else if (place.isJoint(moves.pawn(b, b.black_pawn, .black))) {
            return true;
        }
    }

    return false;
}

/// その色に一つ以上の動かせる駒があるかどうか判定する
pub fn canMove(board: Board, color: Color) bool {
    // 自分の色のすべての駒をループ
    var iter = board.getColorPieces(color).iterator();
    while (iter.next()) |current| {
        // 動ける場所が1つでもあれば真を返して終了
        if (!board.getMove(BitBoard.fromIndex(current)).isEmpty()) {
            return true;
        }
    }

    // 最後まで探索して見つからなかった場合は偽
    return false;
}

/// 材料の不足による引き分けを判定する
pub fn isInsufficientMaterial(board: Board) bool {
    // ポーン、ルーク、クイーンのいずれかが1つ以上ある場合、チェックメイトの可能性がある
    // ルークとクイーンは
    if (!board.black_pawn.isEmpty() or
        !board.black_rook.isEmpty() or
        !board.black_queen.isEmpty() or
        !board.white_pawn.isEmpty() or
        !board.white_rook.isEmpty() or
        !board.white_queen.isEmpty())
    {
        return false;
    }

    // キング対キング
    if (board.black_knight.isEmpty() and
        board.black_bishop.isEmpty() and
        board.white_knight.isEmpty() and
        board.white_bishop.isEmpty())
    {
        return true;
    }

    const bn = board.black_knight.count(); // black knight count
    const bb = board.black_bishop.count(); // black bishop count
    const wn = board.white_knight.count(); // white knight count
    const wb = board.white_bishop.count(); // white bishop count

    // キングとビショップ対キング
    if ((bn == 0 and bb == 1 and wn == 0 and wb == 0) or
        (bn == 0 and bb == 0 and wn == 0 and wb == 1))
    {
        return true;
    }

    // キングとナイト対キング
    if ((bn == 1 and bb == 0 and wn == 0 and wb == 0) or
        (bn == 0 and bb == 0 and wn == 1 and wb == 0))
    {
        return true;
    }

    const bishops = board.black_bishop.unions(board.white_bishop);

    // キングとビショップ対キングとビショップ、ビショップは同じ色のマスにいる
    if (bn == 0 and
        wn == 0 and
        (bishops.masks(position.black_square_mask).eql(bishops) or
        bishops.masks(position.white_square_mask).eql(bishops)))
    {
        return true;
    }

    return false;
}

/// ボードから動いた状態の新しいボードを作成する。
/// 1. 移動元と移動先のマスを空にする。
/// 2. 移動先のマスを指定のピースにする。
pub fn getMovedBoard(b: Board, from: BitBoard, to: BitBoard) Board {
    const piece_type = b.getColorType(from) orelse return b;
    const to_piece_type = b.getColorType(to);

    if (piece_type.pieceType() == .king and
        to_piece_type != null and
        piece_type.color() == to_piece_type.?.color() and
        to_piece_type.?.pieceType() == .rook)
    {
        // 動かし元にキング、動かし先に味方のルークがある場合
        var new_board = b.getMovedBoardCastling(from, to);
        new_board.setEnpassant(from, piece_type);

        return new_board;
    } else if (piece_type.pieceType() == .pawn and
        (from.move(.ne).eql(to) or
        from.move(.se).eql(to) or
        from.move(.nw).eql(to) or
        from.move(.sw).eql(to)) and
        to_piece_type == null)
    {
        // ポーンが斜めに動いて動かし先に駒がない場合
        return b.getMovedBoardEnpassant(from, to);
    } else {
        // その他の場合
        var new_board = b.getMovedBoardNormalMove(from, to);
        new_board.setEnpassant(from, piece_type);

        // 次にアンパサンが起こる動きならアンパサンの移動先を代入する
        if (piece_type.pieceType() == .pawn and from.move(.n).move(.n).eql(to)) {
            new_board.enpassant_target = from.move(.n);
        } else if (piece_type.pieceType() == .pawn and from.move(.s).move(.s).eql(to)) {
            new_board.enpassant_target = from.move(.s);
        } else {
            new_board.enpassant_target = BitBoard.init();
        }

        return new_board;
    }
}

fn getMovedBoardNormalMove(b: Board, from: BitBoard, to: BitBoard) Board {
    var new_board = b;

    const from_piece_type = new_board.getColorType(from) orelse return new_board;
    const to_piece_type = new_board.getColorType(to);

    if (to_piece_type) |tpt| {
        // 行き先に駒があるなら取り除く

        const to_inv = to.inversed();
        switch (tpt) {
            .black_pawn => new_board.black_pawn.setMask(to_inv),
            .black_knight => new_board.black_knight.setMask(to_inv),
            .black_bishop => new_board.black_bishop.setMask(to_inv),
            .black_rook => new_board.black_rook.setMask(to_inv),
            .black_queen => new_board.black_queen.setMask(to_inv),
            .black_king => new_board.black_king.setMask(to_inv),

            .white_pawn => new_board.white_pawn.setMask(to_inv),
            .white_knight => new_board.white_knight.setMask(to_inv),
            .white_bishop => new_board.white_bishop.setMask(to_inv),
            .white_rook => new_board.white_rook.setMask(to_inv),
            .white_queen => new_board.white_queen.setMask(to_inv),
            .white_king => new_board.white_king.setMask(to_inv),
        }
    }

    // 動かす駒について元と先のビットを反転させる
    const from_to = from.unions(to);
    switch (from_piece_type) {
        .black_pawn => new_board.black_pawn.setToggle(from_to),
        .black_knight => new_board.black_knight.setToggle(from_to),
        .black_bishop => new_board.black_bishop.setToggle(from_to),
        .black_rook => new_board.black_rook.setToggle(from_to),
        .black_queen => new_board.black_queen.setToggle(from_to),
        .black_king => new_board.black_king.setToggle(from_to),

        .white_pawn => new_board.white_pawn.setToggle(from_to),
        .white_knight => new_board.white_knight.setToggle(from_to),
        .white_bishop => new_board.white_bishop.setToggle(from_to),
        .white_rook => new_board.white_rook.setToggle(from_to),
        .white_queen => new_board.white_queen.setToggle(from_to),
        .white_king => new_board.white_king.setToggle(from_to),
    }

    return new_board;
}

/// キャスリングをした後のボードを得る
fn getMovedBoardCastling(b: Board, from: BitBoard, to: BitBoard) Board {
    var new_board = b;

    if (from.eql(position.white_king)) {
        // e1は白のキング
        if (to.eql(position.white_rook_queenside)) {
            // クイーンサイド
            new_board.white_king.setToggle(position.white_bishop_queenside.unions(position.white_king));
            new_board.white_rook.setToggle(position.white_rook_queenside.unions(position.white_queen));
        } else if (to.eql(position.white_rook_kingside)) {
            // キングサイド
            new_board.white_king.setToggle(position.white_king.unions(position.white_knight_kingside));
            new_board.white_rook.setToggle(position.white_bishop_kingside.unions(position.white_rook_kingside));
        }
    } else if (from.eql(position.white_king)) {
        // e8は黒のキング
        if (to.eql(position.black_rook_queenside)) {
            // クイーンサイド
            new_board.black_king.setToggle(position.black_bishop_queenside.unions(position.black_king));
            new_board.black_rook.setToggle(position.black_rook_queenside.unions(position.black_queen));
        } else if (to.eql(position.black_rook_kingside)) {
            // キングサイド
            new_board.black_king.setToggle(position.black_king.unions(position.black_knight_kingside));
            new_board.black_rook.setToggle(position.black_bishop_kingside.unions(position.black_rook_kingside));
        }
    }

    return new_board;
}

/// アンパサンを実行した後のボードを得る
fn getMovedBoardEnpassant(b: Board, from: BitBoard, to: BitBoard) Board {
    var new_board = b;

    const from_piece_type = new_board.getColorType(from) orelse return new_board;

    // 移動先のマスの1つ後ろの駒
    var capture_target: BitBoard = undefined;

    switch (from_piece_type) {
        .black_pawn => {
            new_board.black_pawn.setToggle(from.unions(to));
            capture_target = to.move(.n);
        },

        .white_pawn => {
            new_board.white_pawn.setToggle(from.unions(to));
            capture_target = to.move(.s);
        },

        else => {},
    }

    // 駒を取り除く
    const capture_piece_type = new_board.getColorType(capture_target);

    if (capture_piece_type) |cpt| {
        const capture_inv = capture_target.inversed();
        switch (cpt) {
            .black_pawn => new_board.black_pawn.setMask(capture_inv),
            .black_knight => new_board.black_knight.setMask(capture_inv),
            .black_bishop => new_board.black_bishop.setMask(capture_inv),
            .black_rook => new_board.black_rook.setMask(capture_inv),
            .black_queen => new_board.black_queen.setMask(capture_inv),
            .black_king => new_board.black_king.setMask(capture_inv),

            .white_pawn => new_board.white_pawn.setMask(capture_inv),
            .white_knight => new_board.white_knight.setMask(capture_inv),
            .white_bishop => new_board.white_bishop.setMask(capture_inv),
            .white_rook => new_board.white_rook.setMask(capture_inv),
            .white_queen => new_board.white_queen.setMask(capture_inv),
            .white_king => new_board.white_king.setMask(capture_inv),
        }
    }

    return new_board;
}

/// キャスリングのキングとルークの動きを判定
fn setEnpassant(board: *Board, from: BitBoard, piece_type: ColorPieceType) void {
    switch (piece_type) {
        .black_king => {
            board.castling_available.black_kingside = false;
            board.castling_available.black_queenside = false;
        },
        .black_rook => {
            if (from.eql(position.black_rook_queenside)) {
                board.castling_available.black_queenside = false;
            } else if (from.eql(position.black_rook_kingside)) {
                board.castling_available.black_kingside = false;
            }
        },
        .white_king => {
            board.castling_available.white_kingside = false;
            board.castling_available.white_queenside = false;
        },
        .white_rook => {
            if (from.eql(position.white_rook_queenside)) {
                board.castling_available.white_queenside = false;
            } else if (from.eql(position.white_rook_kingside)) {
                board.castling_available.white_kingside = false;
            }
        },
        else => {},
    }
}

/// ボードからプロモーションした状態の新しいボードを作成する。
pub fn getPromotionBoard(board: Board, from: BitBoard, piece_type: PieceType) Board {
    var new_board = board;

    const color_piece_type = board.getColorType(from) orelse return new_board;

    switch (color_piece_type) {
        .black_pawn => {
            new_board.black_pawn.setMask(from.inversed());

            switch (piece_type) {
                .knight => new_board.black_knight.setUnion(from),
                .bishop => new_board.black_bishop.setUnion(from),
                .rook => new_board.black_rook.setUnion(from),
                .queen => new_board.black_queen.setUnion(from),
                else => {},
            }
        },
        .white_pawn => {
            new_board.white_pawn.setMask(from.inversed());

            switch (piece_type) {
                .knight => new_board.white_knight.setUnion(from),
                .bishop => new_board.white_bishop.setUnion(from),
                .rook => new_board.white_rook.setUnion(from),
                .queen => new_board.white_queen.setUnion(from),
                else => {},
            }
        },
        else => {},
    }

    return new_board;
}
