extends RefCounted

# The visible ground AND its collisions are cut with the same rectangles.
# Rect2 axes are world X,Z. One opening per broad, bidirectional access ramp.
const OPENINGS: Array[Rect2] = [Rect2(-70,-11,8,21), Rect2(-46,-43,8,21)]

static func pieces(rect: Rect2) -> Array[Rect2]:
    var pending: Array[Rect2] = [rect]
    for hole in OPENINGS:
        var next: Array[Rect2] = []
        for part in pending:
            var overlap: Rect2 = part.intersection(hole)
            if not overlap.has_area():
                next.append(part)
                continue
            var candidates: Array[Rect2] = [
                Rect2(part.position,Vector2(part.size.x,overlap.position.y-part.position.y)),
                Rect2(Vector2(part.position.x,overlap.end.y),Vector2(part.size.x,part.end.y-overlap.end.y)),
                Rect2(Vector2(part.position.x,overlap.position.y),Vector2(overlap.position.x-part.position.x,overlap.size.y)),
                Rect2(Vector2(overlap.end.x,overlap.position.y),Vector2(part.end.x-overlap.end.x,overlap.size.y))]
            for candidate in candidates:
                if candidate.size.x > 0.001 and candidate.size.y > 0.001:
                    next.append(candidate)
        pending = next
    return pending

static func overlaps(at: Vector3, size_value: Vector3) -> bool:
    var rect: Rect2 = Rect2(Vector2(at.x-size_value.x*0.5,at.z-size_value.z*0.5),Vector2(size_value.x,size_value.z))
    for hole in OPENINGS:
        if rect.intersects(hole):
            return true
    return false
