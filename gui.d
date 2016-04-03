#!/usr/bin/env rdmd

import std.conv;
import std.math;
import std.stdio;
import std.array;
import std.algorithm;

import physics;
import simpledisplay;

void main(string[] args) {
    auto  window = new SimpleWindow(Size(1000, 700), "Oh My Stars");
    Space space;

    void drawBody(Body b) {
        auto painter = window.draw();

        painter.outlineColor = Color.black;

        painter.fillColor    = b.color;
        painter.drawEllipse(Point((b.x-b.radius).to!int,
                                  (b.y-b.radius).to!int),
                            Point((b.x+b.radius).to!int,
                                  (b.y+b.radius).to!int));
    }

    void drawSpace() {
        debug writeln("Drawing space: ", space.bodies);
        auto painter = window.draw();

        painter.outlineColor = Color.black;
        painter.fillColor    = space.color;
        painter.drawRectangle(Point(0, 0), window.width, window.height);
    }

    drawSpace();
    debug {
        space.bodies ~= Body(Coord(290, 120), 50, 1500);
        space.bodies ~= Body(Coord(190, 300), 50, 1500);
        space.bodies ~= Body(Coord(290, 460), 50, 1500);
    }
    space.bodies.each!drawBody;

    void reset() {
        space = Space();
        drawSpace;
    }

    bool pause;
    Body temp_body;
    bool addingBody;
    uint redraw_counter;
    real max_radius;

    window.eventLoop(100,
        delegate () {
            if (pause)
                return;

            space.bodies.each!drawBody;
            space.advance_by(10);

            if (redraw_counter++ == 50) {
                drawSpace();
                redraw_counter = 0;
            }
            space.bodies.each!drawBody;
        },
        delegate (MouseEvent ev) {
            debug ev.writeln;

            if (ev.type == MouseEventType.buttonPressed && !addingBody) {
                addingBody = true;

                debug writeln("Making ", temp_body);
                temp_body = Body(Coord(ev.x, ev.y), 1, 1);
                return;
            }

            if (ev.type == MouseEventType.buttonReleased && addingBody) {
                temp_body.mass = max_radius * 300;
                debug writeln("Inserting ", temp_body);
                space.bodies ~= temp_body;
                addingBody = false;
                drawSpace();
                space.bodies.each!drawBody;
                return;
            }

            if (ev.type == MouseEventType.motion && addingBody) {
                space.bodies.each!drawBody;

                temp_body.radius = temp_body.distance(Coord(ev.x, ev.y))
                                            .round.to!uint;

                max_radius = max(temp_body.radius, max_radius);

                drawBody(temp_body);
                return;
            }
        },
        delegate (KeyEvent ev) {
            if (!ev.pressed)
                return;

            if (ev.key == Key.Space) {
                reset;
                debug writeln("Reset");
                return;
            }

            if (ev.key == Key.P) {
                pause = !pause;
                debug writeln("Pause: ", pause);
                return;
            }

            debug
            if (ev.key == Key.M) {
                writeln("MARKER");
            }
        },
    );
}
