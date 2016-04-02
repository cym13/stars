#!/usr/bin/env rdmd

import std.conv;
import std.math;
import std.stdio;
import std.array;
import std.algorithm;

import physics;
import simpledisplay;

void main(string[] args) {
    auto window = new SimpleWindow(Size(600, 600), "My D App");

    Space space;
    bool  addingBody;
    Body  temp_body;

    void drawBody(Body b) {
        auto painter = window.draw();

        painter.outlineColor = Color.black;
        painter.fillColor    = b.color;
        painter.drawEllipse(Point((b.x-b.radius).to!int,
                                  (b.y-b.radius).to!int),
                            Point((b.x+b.radius).to!int,
                                  (b.y+b.radius).to!int));
    }

    void drawSpace(Space space) {
        debug writeln("Drawing space: ", space.bodies);
        auto painter = window.draw();

        painter.outlineColor = Color.black;
        painter.fillColor    = space.color;
        painter.drawRectangle(Point(0, 0), window.width, window.height);
    }

    drawSpace(space);
    debug {
        space.bodies ~= Body(Coord(270, 190), 30, 1000);
        space.bodies ~= Body(Coord(190, 270), 30, 1000);
    }
    space.bodies.each!drawBody;

    window.eventLoop(100,
        delegate () {
            space.advance_by(100);
            drawSpace(space);
            space.bodies.each!drawBody;
        },
        delegate (MouseEvent ev) {
            debug ev.writeln;

            if (ev.type == MouseEventType.buttonPressed && !addingBody) {
                addingBody = true;

                debug writeln("Making ", temp_body);
                temp_body = Body(Coord(ev.x, ev.y), 1, 1000);
                return;
            }

            if (ev.type == MouseEventType.buttonReleased && addingBody) {
                debug writeln("Inserting ", temp_body);
                space.bodies ~= temp_body;
                addingBody = false;
                drawSpace(space);
                space.bodies.each!drawBody;
                return;
            }

            if (ev.type == MouseEventType.motion && addingBody) {
                space.bodies.each!drawBody;

                temp_body.radius = temp_body.distance(Coord(ev.x, ev.y))
                                            .round.to!uint;
                drawBody(temp_body);
                return;
            }
        },
    );
}
