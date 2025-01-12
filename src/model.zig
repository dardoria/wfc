const std = @import("std");

pub const Heuristic = enum { Entropy, MRV, Scanline };

pub const Model = struct {
    allocator: std.mem.Allocator,
    wave: [][]bool,
    propagator: [][][]i32,
    compatible: [][][]i32,
    observed: []i32,
    stack: []std.meta.Tuple(&[_]type{ i32, i32 }),
    stacksize: i32,
    observedSoFar: i32,

    width: u32,
    height: u32,
    weights_count: i32,
    step: i32,
    periodic: bool,

    weights: []f64,
    weightLogWeights: []f64,
    distribution: []f64,

    sumsOfOnes: []i32,
    sumOfWeights: f64,
    sumOfWeightLogWeights: f64,
    startingEntropy: f64,

    sumsOfWeights: []f64,
    sumsOfWeightLogWeights: []f64,
    entropies: []f64,

    heuristic: Heuristic,

    pub fn new(allocator: std.mem.Allocator, width: u32, height: u32, step: i32, periodic: bool, heuristic: Heuristic) !Model {
        const weights_count = 3; // Changed from 0 to have some initial data
        const dim = width * height;

        // Allocate arrays
        var wave = try allocator.alloc([]bool, dim);
        for (wave) |*row| {
            row.* = try allocator.alloc(bool, weights_count);
            @memset(row.*, true);
        }

        var weights = try allocator.alloc(f64, weights_count);
        @memset(weights, 1.0); // Initialize with equal weights

        var weightLogWeights = try allocator.alloc(f64, weights_count);
        var distribution = try allocator.alloc(f64, weights_count);
        var observed = try allocator.alloc(i32, dim);
        @memset(observed, -1);

        var sumsOfOnes = try allocator.alloc(i32, dim);
        @memset(sumsOfOnes, weights_count);

        var sumsOfWeights = try allocator.alloc(f64, dim);
        var sumsOfWeightLogWeights = try allocator.alloc(f64, dim);
        var entropies = try allocator.alloc(f64, dim);

        // Calculate initial weights and entropy
        var sumOfWeights: f64 = 0;
        var sumOfWeightLogWeights: f64 = 0;
        for (weights) |w, i| {
            weightLogWeights[i] = w * std.math.log(w);
            sumOfWeights += w;
            sumOfWeightLogWeights += weightLogWeights[i];
        }

        const startingEntropy = std.math.log(sumOfWeights) - sumOfWeightLogWeights / sumOfWeights;

        // Initialize compatible array
        var compatible = try allocator.alloc([][]i32, dim);
        for (compatible) |*row| {
            row.* = try allocator.alloc([]i32, weights_count);
            for (row.*) |*cell| {
                cell.* = try allocator.alloc(i32, 4);
                @memset(cell.*, 0);
            }
        }

        // Initialize propagator
        var propagator = try allocator.alloc([][]i32, 4);
        for (propagator) |*dir| {
            dir.* = try allocator.alloc([]i32, weights_count);
            for (dir.*) |*cell| {
                cell.* = try allocator.alloc(i32, weights_count);
                @memset(cell.*, 0);
            }
        }

        var stack = try allocator.alloc(std.meta.Tuple(&[_]type{ i32, i32 }), dim * step);

        return Model{
            .allocator = allocator,
            .wave = wave,
            .propagator = propagator,
            .compatible = compatible,
            .observed = observed,
            .stack = stack,
            .stacksize = 0,
            .observedSoFar = 0,

            .width = width,
            .height = height,
            .weights_count = weights_count,
            .step = step,
            .periodic = periodic,

            .weights = weights,
            .weightLogWeights = weightLogWeights,
            .distribution = distribution,

            .sumsOfOnes = sumsOfOnes,
            .sumOfWeights = sumOfWeights,
            .sumOfWeightLogWeights = sumOfWeightLogWeights,
            .startingEntropy = startingEntropy,

            .sumsOfWeights = sumsOfWeights,
            .sumsOfWeightLogWeights = sumsOfWeightLogWeights,
            .entropies = entropies,

            .heuristic = heuristic,
        };
    }

    pub fn deinit(self: *Model) void {
        // Free all allocated memory
        for (self.wave) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.wave);

        for (self.propagator) |dir| {
            for (dir) |cell| {
                self.allocator.free(cell);
            }
            self.allocator.free(dir);
        }
        self.allocator.free(self.propagator);

        for (self.compatible) |row| {
            for (row) |cell| {
                self.allocator.free(cell);
            }
            self.allocator.free(row);
        }
        self.allocator.free(self.compatible);

        self.allocator.free(self.observed);
        self.allocator.free(self.stack);
        self.allocator.free(self.weights);
        self.allocator.free(self.weightLogWeights);
        self.allocator.free(self.distribution);
        self.allocator.free(self.sumsOfOnes);
        self.allocator.free(self.sumsOfWeights);
        self.allocator.free(self.sumsOfWeightLogWeights);
        self.allocator.free(self.entropies);
    }
};
