using UnityEngine;

public class FreeCameraController : MonoBehaviour
{
    [Header("Movement")]
    public float moveSpeed = 10f;
    public float fastMoveMultiplier = 3f;
    public KeyCode fastMoveKey = KeyCode.LeftShift;

    [Header("Rotation")]
    public float rotateSensitivity = 3f;
    public KeyCode rotateKey = KeyCode.Mouse1;

    [Header("Pan")]
    public float panSpeed = 0.5f;
    public KeyCode panKey = KeyCode.Mouse2;

    [Header("Zoom")]
    public float zoomSpeed = 5f;
    public float zoomMin = 1f;
    public float zoomMax = 50f;
    public bool invertScroll = false;

    private Vector3 _lastMousePos;

    void Update()
    {
        // 缩放
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        if (scroll != 0f)
        {
            float zoomDelta = scroll * zoomSpeed * (invertScroll ? -1f : 1f);
            transform.position += transform.forward * zoomDelta;

            // 限制与原点距离
            if (Vector3.Distance(transform.position, Vector3.zero) > zoomMax)
                transform.position = Vector3.ClampMagnitude(transform.position, zoomMax);
            if (Vector3.Distance(transform.position, Vector3.zero) < zoomMin)
                transform.position = transform.position.normalized * zoomMin;
        }

        // 旋转
        if (Input.GetKeyDown(rotateKey))
            _lastMousePos = Input.mousePosition;

        if (Input.GetKey(rotateKey))
        {
            Vector3 delta = Input.mousePosition - _lastMousePos;
            _lastMousePos = Input.mousePosition;

            float yaw = delta.x * rotateSensitivity * 0.1f;
            float pitch = -delta.y * rotateSensitivity * 0.1f;

            transform.eulerAngles += new Vector3(pitch, yaw, 0f);
        }

        // 平移
        if (Input.GetKeyDown(panKey))
            _lastMousePos = Input.mousePosition;

        if (Input.GetKey(panKey))
        {
            Vector3 delta = Input.mousePosition - _lastMousePos;
            _lastMousePos = Input.mousePosition;

            Vector3 right = transform.right * -delta.x * panSpeed * 0.01f;
            Vector3 up = transform.up * -delta.y * panSpeed * 0.01f;
            transform.position += right + up;
        }

        // 移动
        float speed = moveSpeed * Time.deltaTime;
        if (Input.GetKey(fastMoveKey)) speed *= fastMoveMultiplier;

        if (Input.GetKey(KeyCode.W)) transform.position += transform.forward * speed;
        if (Input.GetKey(KeyCode.S)) transform.position -= transform.forward * speed;
        if (Input.GetKey(KeyCode.A)) transform.position -= transform.right * speed;
        if (Input.GetKey(KeyCode.D)) transform.position += transform.right * speed;
        if (Input.GetKey(KeyCode.Q)) transform.position -= transform.up * speed;
        if (Input.GetKey(KeyCode.E)) transform.position += transform.up * speed;
    }
}
