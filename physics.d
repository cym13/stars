#!/usr/bin/env rdmd

import std.conv;
import std.stdio;
import std.array;
import std.range;
import std.algorithm;
import std.math;

import arsd.color;

// Gravity constant
immutable G = 6.67*10.^^-5;

struct Coord {
    union {
        real[2] vector = [0, 0];

        struct {
            real x;
            real y;
        }
    }

    this(real x, real y) pure {
        this.x = x;
        this.y = y;
    }

    this(int x, int y) pure {
        this.x = x.to!real;
        this.y = y.to!real;
    }

    this(real[] arr) pure {
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
    real   mass;
    real   radius;
    Coord  position;
    Coord  velocity;
    Color  color;
    Color  trace_color;
    string name;

    static uint counter;

    alias position this;

    this(Coord position, real radius, real mass, Coord velocity=Coord()) {
        import std.random: uniform;

        assert(mass   != 0);
        assert(radius != 0);

        this.mass     = mass;
        this.radius   = radius;
        this.position = position;
        this.velocity = velocity;
        this.color    = Color(uniform(0, 255), uniform(0, 255), uniform(0, 255));
        this.name     = "Body_" ~ counter.to!string;

        counter++;
    }

    Body advance_by(Body[] bodies, int t=10) {
        assert(mass != 0);

        Body result = this;

        result.position.vector[] = vector[] + velocity.vector[] * t / mass;

        result.velocity = bodies.map!(b => gravitation(b, this))
                                .reduce!sum
                                .vector[]
                                .array.Coord
                                .sum(velocity);

        return result;
    }

    string toString() {
        import std.format;
        return name ~ "(position=" ~ position.to!string
                ~ ", radius="      ~ radius.to!string
                ~ ", mass="        ~ mass.to!string
                ~ ", velocity="    ~ velocity.to!string
                ~ ", color="       ~ color.to!string
                ~ ", trace_color=" ~ trace_color.to!string
                ~ ")";
    }
}

struct Space {
    Body[] bodies;
    Color  color = Color.black;

    alias bodies this;

    void advance_by(int t=10) {
        auto new_bodies = bodies.map!(b => b.advance_by(bodies, t)).array;

        foreach (i, ref a; new_bodies) foreach (ref b ; new_bodies[i+1..$]) {
            if (collide(a, b)) {
                debug writeln("Collision! ", a, " ", b);
                auto a_velocity = a.velocity.vector.dup;
                auto b_velocity = b.velocity.vector.dup;

                a.velocity.vector[] += (b_velocity[] - a_velocity[])
                                     * (b.mass / a.mass);
                b.velocity.vector[] += (a_velocity[] - b_velocity[])
                                     * (a.mass / b.mass);
            }
        }

        bodies = new_bodies;
    }

    string toString() {
        return "Space(bodies=" ~ bodies.map!(to!string).join("\n")
                 ~ ", color="  ~ color.to!string ~ ")";
    }
}

Coord gravitation(Body from, Body to) {
    if (from == to)
        return Coord();

    Coord result;

    result.vector[] = (from.vector[] - to.vector[])
                    * G * from.mass * to.mass
                    / (distance(from, to) ^^ 2);

    debug {
        writeln("gravity: ", result, " ; norm: ", result.norm);
        writeln("from: ", from);
        writeln("  to: ", to);
    }

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
