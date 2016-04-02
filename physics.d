#!/usr/bin/env rdmd

import std.conv;
import std.stdio;
import std.array;
import std.range;
import std.algorithm;
import std.math;

import arsd.color;

// Gravity constant
immutable G = 6.67*10.^^-11;

struct Coord {
    union {
        int[2] vector;

        struct {
            int x;
            int y;
        }
    }

    this(int x, int y) pure {
        this.x = x;
        this.y = y;
    }

    this(int[] arr) pure {
        this.vector[] = arr;
    }

    real norm() pure {
        return distance(this, Coord(0, 0));
    }

    string toString() {
        return this.vector.to!string;
    }
}

Coord sum(Coord a, Coord b) pure {
    return zip(a.vector[], b.vector[]).map!(tup => tup[0]+tup[1]).array.Coord;
}

unittest {
    assert(sum(Coord(), Coord()) == Coord());
    assert(sum(Coord(1,  2), Coord(3, 2)) == Coord(4, 4));
    assert(sum(Coord(1, -2), Coord(3, 2)) == Coord(4, 0));
}

struct Body {
    uint  mass;
    uint  radius;
    Coord position;
    Coord momentum;
    Color color;
    Color trace_color;

    // May allow some nicer APIs
    alias position this;

    this(Coord position, uint radius, uint mass,
         Coord momentum    = Coord(),
         Color color       = Color.blue,
         Color trace_color = Color.red) {
        assert(mass   != 0);
        assert(radius != 0);

        this.mass     = mass;
        this.radius   = radius;
        this.position = position;
        this.momentum = momentum;
        this.color    = color;
    }

    Body advance_by(Body[] bodies, int t=10) {
        assert(mass != 0);

        Body result = this;

        Coord new_position = vector[].map!(x => momentum.x * t + x)
                                     .array.Coord;

        Coord new_momentum = bodies.map!(b => gravitation(b, this))
                                   .reduce!sum
                                   .vector[]
                                   .map!(x => round(x / mass).to!int)
                                   .array.Coord
                                   .sum(momentum);

        result.position = new_position;
        result.momentum = new_momentum;

        return result;
    }

    string toString() {
        import std.format;
        return "Body(position=" ~ position.to!string
             ~ ", radius="      ~ radius.to!string
             ~ ", mass="        ~ mass.to!string
             ~ ", momentum="    ~ momentum.to!string
             ~ ", color="       ~ color.to!string
             ~ ", trace_color=" ~ trace_color.to!string
             ~ ")";
    }
}

struct Space {
    Body[] bodies;
    Color  color = Color.black;

    void advance_by(int t=10) {
        bodies = bodies.map!(b => b.advance_by(bodies, t)).array;
    }
}

Coord gravitation(Body from, Body to) {
    if (from == to)
        return Coord();

    Coord result;
    result = zip(from.vector[], to.vector[])
                    .map!(t => sgn(t[0] - t[1])
                               * G * from.mass * to.mass
                               / (t[0] - t[1]) ^^ 2)
                    .map!(x => round(x).to!int)
                    .array.Coord;
    return result;
}

real distance(Coord a, Coord b) pure {
    return zip(a.vector[], b.vector[])
            .map!(tup => (tup[0]-tup[1])*(tup[0]-tup[1]))
            .reduce!"a+b"
            .to!real
            .sqrt;
}

bool collide(Body a, Body b) pure {
    return distance(a, b) <= (a.radius + b.radius);
}
