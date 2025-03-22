const std = @import("std");

const vexlib = @import("../../vexlib/src/vexlib.zig");
const Math = vexlib.Math;
const As = vexlib.As;
const Map = vexlib.Map;
const Array = vexlib.Array;
const Uint8Array = vexlib.Uint8Array;
const Float32Array = vexlib.Float32Array;
const String = vexlib.String;

pub const TextMetrics = struct {
    fontWidth: f32,
    actualBoundingBoxLeft: f32,
    actualBoundingBoxRight: f32,
    actualBoundingBoxAscent: f32,
    actualBoundingBoxDescent: f32,
    fontBoundingBoxAscent: f32,
    fontBoundingBoxDescent: f32
};

pub const QuiteOkFont = struct {
    ascent: f32,
    descent: f32,
    glyphs: Array(Float32Array),
    characterMap: Map(u8, [2]f32)
};

const pow2_8 = Math.pow(As.f32(2), 16);
const QOF_FLOAT_SZ = 3;
fn decodeFloat(bytes: *Uint8Array, off: u32) f32 {
    const a = As.u32(bytes.get(off + 1)) << 8;
    const b = As.u32(bytes.get(off + 2));
    const c = As.u32(bytes.get(off + 0));
    return As.f32(a | b) / pow2_8 * As.f32(Math.pow(2, c & 127)) * (if (bytes.get(off + 0) > 127) As.f32(-1) else As.f32(1));
}
pub fn decodeFont(bytes: *Uint8Array) QuiteOkFont {
    const VERT = 0;
    const QUAD = 1;
    
    var idx: u32 = 3;
    const ascent = decodeFloat(bytes, idx); idx += QOF_FLOAT_SZ;
    const descent = decodeFloat(bytes, idx); idx += QOF_FLOAT_SZ;
    const minW = decodeFloat(bytes, idx); idx += QOF_FLOAT_SZ;
    const maxW = decodeFloat(bytes, idx); idx += QOF_FLOAT_SZ;
    const pXMin = decodeFloat(bytes, idx); idx += QOF_FLOAT_SZ;
    const pXMax = decodeFloat(bytes, idx); idx += QOF_FLOAT_SZ;
    const pYMin = decodeFloat(bytes, idx); idx += QOF_FLOAT_SZ;
    const pYMax = decodeFloat(bytes, idx); idx += QOF_FLOAT_SZ;
    const cmdPad = bytes.get(idx);
    
    // decode character map table
    const charMapTableLen = As.u32(bytes.get(idx+1));
    var characterMap = Map(u8, [2]f32).alloc();
    var i: u32 = idx+2; while (i < idx+2 + charMapTableLen) : (i += 1) {
        characterMap.set(bytes.get(i), [2]f32{
            As.f32(bytes.get(i + charMapTableLen)),
            minW + As.f32(bytes.get(i + charMapTableLen * 2)) / 255 * (maxW - minW)
        });
    }
    
    var cidx = idx+2 + charMapTableLen * 3;
    const glyphsLen = As.u32(bytes.get(cidx));
    var glyphs = Array(Float32Array).alloc(glyphsLen);
    var currGlyph = Float32Array.alloc(4);
    const endOff = (As.u32(bytes.get(cidx + 1)) << 8) | As.u32(bytes.get(cidx + 2));
    cidx += 3;
    const startI = cidx;
    var pIdx = startI + endOff;
    while (cidx < startI + endOff) {
        const seg = [_]u8{
            bytes.get(cidx) >> 6,
            (bytes.get(cidx) >> 4) & 3,
            (bytes.get(cidx) >> 2) & 3,
            bytes.get(cidx) & 3
        };
        var has3 = false;
        var k: usize = 0; while (k < seg.len) : (k += 1) {
            if (seg[k] == 3) {
                has3 = true;
                break;
            }
        }

        var pad: u32 = 0;
        if (glyphs.len == glyphsLen - 1 and has3) {
            pad = cmdPad;
        }
        var j: u32 = 0; while (j < seg.len - pad) : (j += 1) {
            if (seg[j] == 3) {
                glyphs.append(currGlyph);
                currGlyph = Float32Array.alloc(4);
            } else {
                currGlyph.append(As.f32(seg[j]));
                if (seg[j] == VERT) {
                    const a = Math.map(As.f32(bytes.get(pIdx)), 0, 255, pXMin, pXMax);
                    pIdx += 1;
                    const b = Math.map(As.f32(bytes.get(pIdx)), 0, 255, pYMin, pYMax);
                    pIdx += 1;
                    currGlyph.append(a);
                    currGlyph.append(b);
                } else if (seg[j] == QUAD) {
                    const a = Math.map(As.f32(bytes.get(pIdx)), 0, 255, pXMin, pXMax);
                    pIdx += 1;
                    const b = Math.map(As.f32(bytes.get(pIdx)), 0, 255, pYMin, pYMax);
                    pIdx += 1;
                    const c = Math.map(As.f32(bytes.get(pIdx)), 0, 255, pXMin, pXMax);
                    pIdx += 1;
                    const d = Math.map(As.f32(bytes.get(pIdx)), 0, 255, pYMin, pYMax);
                    pIdx += 1;
                    currGlyph.append(a);
                    currGlyph.append(b);
                    currGlyph.append(c);
                    currGlyph.append(d);
                }
            }
        }
        cidx += 1;
    }
    
    return QuiteOkFont{
        .ascent = ascent,
        .descent = descent,
        .glyphs = glyphs,
        .characterMap = characterMap
    };
}

pub fn measureText(
    txt: *String, myFont: QuiteOkFont, sz: f32
) ?TextMetrics {
    const VERT = 0;
    const QUAD = 1;
    const HOLE = 2;
    
    const szScl = As.f32(sz);

    var fontWidth: f32 = 0;
    var offX: f32 = 0;
    var endOffX : f32= 0;
    var offY = Math.Infinity(f32);
    var offEndY: f32 = 0;

    const spaceChData = myFont.characterMap.get(32).?;
    const spaceRenderWidth = spaceChData[1] * szScl;

    var line = txt;
    var t: u32 = 0; while (t < line.len()) : (t += 1) {
        if (line.charAt(t) == '\n') {
            continue;
        }

        const chCode = line.charCodeAt(t);
        const chDataOrNull = myFont.characterMap.get(chCode);
        var chData: [2]f32 = undefined;
        if (chDataOrNull != null) {
            chData = chDataOrNull.?;
        } else {
            @panic("Unsupported Character");
        }
        const idx = As.u32(chData[0] - 1);
        const width = chData[1];
        const glyph = myFont.glyphs.get(idx);

        var minX = Math.Infinity(f32);
        var maxX: f32 = -1;
        var minY = Math.Infinity(f32);
        var maxY: f32 = -1;
        
        var i: u32 = 0;
        while (i < glyph.len) {
            var shape = glyph.get(i);
            if (shape == HOLE) {
                i += 1;
            }
            
            shape = glyph.get(i);
            if (shape == VERT) {
                const xPos = glyph.get(i+1) * szScl;
                const yPos = glyph.get(i+2) * szScl;
                
                if (xPos < minX) {
                    minX = xPos;
                }
                if (xPos > maxX) {
                    maxX = xPos;
                }
                if (yPos < minY) {
                    minY = yPos;
                }
                if (yPos > maxY) {
                    maxY = yPos;
                }
                
                i += 3;
            } else if (shape == QUAD) {
                // const cpxPos = glyph.get(i+1) * szScl;
                // const cpyPos = glyph.get(i+2) * szScl;
                const xPos = glyph.get(i+3) * szScl;
                const yPos = glyph.get(i+4) * szScl;
                
                if (xPos < minX) {
                    minX = xPos;
                }
                if (xPos > maxX) {
                    maxX = xPos;
                }
                if (yPos < minY) {
                    minY = yPos;
                }
                if (yPos > maxY) {
                    maxY = yPos;
                }
                
                i += 5;
            }
        }
        
        const renderWidth = width * szScl;
        fontWidth += renderWidth;
        
        if (minY != Math.Infinity(f32) and minY < offY) {
            offY = minY;
        }
        if (maxY != -1 and maxY > offEndY) {
            offEndY = maxY;
        }
        
        if (t == 0) {
            offX = minX;
        }
        if (txt.charAt(t) != ' ') {
            endOffX = renderWidth - maxX;
        } else {
            endOffX += spaceRenderWidth;
        }
    }

    const ascent = myFont.ascent * szScl;
    const descent = myFont.descent * szScl;
    
    return TextMetrics{
        .fontWidth = fontWidth,
        .actualBoundingBoxLeft = offX,
        .actualBoundingBoxRight = fontWidth - endOffX,
        .actualBoundingBoxAscent = -offY,
        .actualBoundingBoxDescent = offEndY,
        .fontBoundingBoxAscent = ascent,
        .fontBoundingBoxDescent = descent
    };
}