using UnityEngine;

public class DrawAxesGizmo : MonoBehaviour
{
    public float axisLength = 0.5f;
    public Color xColor = Color.red;
    public Color yColor = Color.green;
    public Color zColor = Color.blue;

    void OnDrawGizmos()
    {
        Vector3 pos = transform.position;
        Vector3 right = transform.right;
        Vector3 up = transform.up;
        Vector3 forward = transform.forward;

        // X 轴 (双向)
        Gizmos.color = xColor;
        Gizmos.DrawRay(pos, right * axisLength);
        Gizmos.DrawRay(pos, -right * axisLength);

        // Y 轴 (双向)
        Gizmos.color = yColor;
        Gizmos.DrawRay(pos, up * axisLength);
        Gizmos.DrawRay(pos, -up * axisLength);

        // Z 轴 (双向)
        Gizmos.color = zColor;
        Gizmos.DrawRay(pos, forward * axisLength);
        Gizmos.DrawRay(pos, -forward * axisLength);
    }
}
