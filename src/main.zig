const std = @import("std");

const width = 20;
const height = 20;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var grid = try allocator.alloc([]u1, height);
    for (grid) |_, i| {
        grid[i] = try allocator.alloc(u1, width);
    }

    var r = std.rand.Sfc64.init(0);
    for (grid) |row, i| {
        for (row) |cell, j| {
            grid[i][j] = r.random.int(u1);
        }
    }

    while (true) {
        try printGrid(grid, allocator);
        grid = try expandGrid(grid, allocator);
        grid = try nextTurn(grid);
        std.os.nanosleep(0, 100_000_000);
    }
}

fn nextTurn(grid: [][]u1) ![][]u1 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var shifted_grids: [8][][]u1 = undefined;
    const shift_range = [3]i2{ -1, 0, 1 };
    var sgi: usize = 0;
    for (shift_range) |k| {
        for (shift_range) |r| {
            if (k != 0 or r != 0) {
                shifted_grids[sgi] = try shiftGrid(grid, k, r, allocator);
                sgi += 1;
            }
        }
    }

    for (grid) |row, i| {
        for (row) |cell, j| {
            var ncount: usize = 0;
            for (shifted_grids) |sgrid| {
                ncount += sgrid[i][j];
            }
            grid[i][j] = if (ncount == 3 or (ncount == 2 and grid[i][j] == 1)) 1 else 0;
        }
    }

    return grid;
}

fn expandGrid(grid: [][]u1, allocator: *std.mem.Allocator) ![][]u1 {
    const expand_size = 1;
    var expand_ver: usize = 0;
    var expand_hor: usize = 0;

    for (grid[0]) |cell| {
        if (cell == 1) {
            expand_ver += expand_size;
            break;
        }
    }

    for (grid[grid.len - 1]) |cell| {
        if (cell == 1) {
            expand_ver += expand_size;
            break;
        }
    }

    for (grid) |row| {
        if (row[0] == 1) {
            expand_hor += expand_size;
            break;
        }
    }

    for (grid) |row| {
        if (row[row.len - 1] == 1) {
            expand_hor += expand_size;
            break;
        }
    }

    if (expand_ver > 0 or expand_hor > 0) {
        if (expand_ver % 2 == 1) {
            expand_ver += 1;
        }
        if (expand_hor % 2 == 1) {
            expand_hor += 1;
        }

        var new_grid = try allocator.alloc([]u1, grid.len + expand_ver);
        for (new_grid) |_, i| {
            new_grid[i] = try allocator.alloc(u1, grid[0].len + expand_hor);
        }

        var ver_offset = expand_ver / 2;
        var hor_offset = expand_hor / 2;
        for (grid) |row, i| {
            defer allocator.free(row);
            for (row) |cell, j| {
                new_grid[i + ver_offset][j + hor_offset] = cell;
            }
        }
        defer allocator.free(grid);

        return new_grid;
    } else {
        return grid;
    }
}

fn shiftGrid(grid: [][]u1, hor: isize, ver: isize, allocator: *std.mem.Allocator) ![][]u1 {
    var current_width: isize = @intCast(isize, grid[0].len);
    var current_height: isize = @intCast(isize, grid.len);

    var new_grid = try allocator.alloc([]u1, grid.len);

    for (grid) |row, i| {
        var new_row = try allocator.alloc(u1, row.len);

        for (row) |cell, j| {
            new_row[@intCast(usize, @mod(@intCast(isize, j) + hor, current_width))] = cell;
        }
        new_grid[@intCast(usize, @mod(@intCast(isize, i) + ver, current_height))] = new_row;
    }

    return new_grid;
}

fn printGrid(grid: [][]u1, allocator: *std.mem.Allocator) !void {
    var result = try allocator.alloc(u8, (grid.len * grid[0].len) + grid.len);
    defer allocator.free(result);
    for (grid) |row, i| {
        result[(i * grid[0].len) + i] = '\n';
        for (row) |cell, j| {
            result[(i * grid[0].len) + j + i + 1] = if (cell == 1) '@' else ' ';
        }
    }
    std.debug.print("\x1bc", .{});
    std.debug.print("{}", .{result});
}
