using UnityEngine;

[ExecuteAlways]
public class FaceVectorBinder : MonoBehaviour
{
    public GameObject HeadCenter;
    public GameObject HeadForward;
    public GameObject HeadRight;
    public Material[] targetMaterials;

    void Update()
    {
        if (targetMaterials == null || targetMaterials.Length == 0) return;

        foreach (Material mat in targetMaterials)
        {
            if (mat == null) continue;

            if (HeadCenter != null)
                mat.SetVector("_HeadCenter", HeadCenter.transform.position);

            if (HeadCenter != null && HeadForward != null)
            {
                Vector3 fwd = (HeadForward.transform.position - HeadCenter.transform.position).normalized;
                mat.SetVector("_HeadForward", new Vector4(fwd.x, fwd.y, fwd.z, 0));
            }

            if (HeadCenter != null && HeadRight != null)
            {
                Vector3 right = (HeadRight.transform.position - HeadCenter.transform.position).normalized;
                mat.SetVector("_HeadRight", new Vector4(right.x, right.y, right.z, 0));

                Vector3 fwd = (HeadForward != null)
                    ? (HeadForward.transform.position - HeadCenter.transform.position).normalized
                    : Vector3.forward;
                Vector3 up = Vector3.Cross(right, fwd).normalized;
                mat.SetVector("_HeadUp", new Vector4(up.x, up.y, up.z, 0));
            }
        }
    }
}
